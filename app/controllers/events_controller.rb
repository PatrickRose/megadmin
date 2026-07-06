# frozen_string_literal: true

# Controller for events pages
class EventsController < ApplicationController
  before_action :authenticate_organiser!
  load_and_authorize_resource

  def index
    # Events that you own
    @my_events = Event.joins(:organiser_to_events).where(organiser_id: current_organiser.id).uniq.compact
    organiser_events = OrganiserToEvent.where(organiser_id: current_organiser.id)

    # Events that you are organising
    @organiser_events = organiser_events.where(read_only: false).map(&:event).uniq.compact

    # Events that you are a member of the control team for
    @control_team_events = organiser_events.where(read_only: true).map(&:event).uniq.compact

    events = (@my_events + @organiser_events + @control_team_events).uniq(&:id)

    @upcoming_events = events.select { |e| e.date >= Time.zone.now }.sort_by(&:date)
    @previous_events = events.select { |e| e.date < Time.zone.now }.sort_by(&:date).reverse
  end

  def show
    @event = Event.find(params.expect(:id))
    @control_team = OrganiserToEvent.where(organiser_id: current_organiser.id,
                                           event_id: @event.id).pick(:read_only)

    return if @event.google_maps_link.nil?

    @first_index = @event.google_maps_link.index('"')
    return if @first_index.nil?

    @second_index = @event.google_maps_link[@first_index..].index('"', @first_index + 1)
    @just_link = @event.google_maps_link[@first_index + 1, @second_index - 1]
  end

  def new
    @event = Event.new
  end

  def edit
    @event = Event.find(params.expect(:id))
  end

  def create
    final_params = event_params.merge(draft: params[:draft])
    @event = Event.new(final_params)

    if @event.save
      if @event.draft
        redirect_to event_path(id: @event.id), notice: 'Event was successfully saved as draft.', status: :see_other
      else
        redirect_to event_path(id: @event.id), notice: 'Event was successfully created.', status: :see_other
      end

      org_to_event = OrganiserToEvent.new(event_id: @event.id, organiser_id: event_params[:organiser_id],
                                          read_only: false)
      org_to_event.save
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @event = Event.find(params.expect(:id))

    # Sanitize map iframe with rules in /config/initializers/sanitize.rb
    map_link = event_params[:google_maps_link]
    clean_link = Sanitize.fragment(map_link, GOOGLE_MAPS_SANITIZER)
    # If link is filtered show warning
    if map_link != clean_link
      params[:google_maps_link] = nil
      @event.update(google_maps_link: nil)
      redirect_to edit_event_path(id: @event.id), alert: 'Invalid input for Google Maps Iframe.', status: :see_other
      nil
    elsif @event.update(event_params)
      purge_marked_attachments(@event, :rulebook)
      purge_additional_documents(@event)
      redirect_to event_path(id: @event.id), notice: 'Event was successfully updated.', status: :see_other
      nil
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event = Event.find(params.expect(:id))

    @event.destroy

    redirect_to events_path, notice: 'Event was successfully deleted.', status: :see_other
  end

  def pdf
    event = Event.find(params.expect(:event_id))
    event.to_pdf
    redirect_to event_path(id: event.id), notice: 'The .docx files have been successfully converted to .pdf.',
                                          status: :see_other
  end

  # Publish a draft event
  def publish
    @event = Event.find(params.expect(:id))

    if @event.update(draft: false)
      redirect_to event_path(id: @event.id), notice: 'Event was successfully published.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def email
    event = Event.find(params.expect(:id))
    signups = event.event_signups
    email_note = params[:email_note]
    organiser = Organiser.find_by(id: event.organiser_id)

    if event.draft
      redirect_to event_path(event_id: event.id), alert: 'Event needs to be published to send emails'
      return
    end

    signups.each do |i|
      if i.role.nil?
        redirect_to event_event_signups_path(event_id: event.id), alert: 'a signup is missing a role'
        return
      end
    end

    if signups.none?
      redirect_to event_path(event_id: event.id), alert: 'There are no signups to email'
      return
    end

    # Default to only players who haven't been emailed yet; ticking "resend to
    # all" emails everyone regardless.
    recipients = params[:resend_all] == '1' ? signups : signups.where(brief_emailed_at: nil)

    if recipients.none?
      redirect_to event_event_signups_path(event_id: event.id),
                  alert: 'All players have already been emailed. Tick "Resend to players ' \
                         'who have already been emailed" to send to them again.'
      return
    end

    # One job per recipient so a delivery failure only retries that recipient,
    # rather than Delayed Job re-running one big batch job and re-sending to
    # everyone already emailed.
    recipients.each do |signup|
      SendBriefEmailJob.perform_later(signup, event, email_note, organiser)
    end

    redirect_to event_path(event_id: event.id), notice: 'Emails sent'
  end

  private

  def event_params
    permitted = params.expect(event: [:name, :description, :location, :google_maps_link, :date, :timetable,
                                      :additional_info, :organiser_id, :rulebook, :remove_rulebook,
                                      :draft, { additional_documents: [], remove_additional_document_ids: [] }])
    keep_existing_files(permitted, :rulebook, :additional_documents)
  end

  # Purges the additional documents whose attachment ids were ticked for removal.
  def purge_additional_documents(event)
    ids = Array(event.remove_additional_document_ids).compact_blank.map(&:to_i)
    return if ids.empty?

    event.additional_documents.select { |doc| ids.include?(doc.id) }.each(&:purge)
  end
end
