# frozen_string_literal: true

# Controller for team management pages
class TeamsController < ApplicationController
  before_action :authenticate_organiser!
  load_and_authorize_resource

  # Public methods
  def index
    begin
      @event = Event.find(params.expect(:event_id))
    rescue ActiveRecord::RecordNotFound
      @error = 'Event could not be found'
    end

    organiser = OrganiserToEvent.find_by(organiser_id: current_organiser.id, event_id: @event)
    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) if organiser.nil?
    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) unless can? :read, @event

    @organiser = organiser.read_only
    @teams = @event.teams
  end

  def show
    @event = Event.find(params.expect(:event_id))

    organiser = OrganiserToEvent.find_by(organiser_id: current_organiser.id, event_id: @event)
    @organiser = organiser.read_only

    @team = Team.find(params.expect(:id))
  end

  def new
    @event = Event.find(params.expect(:event_id))
    @team = Team.new
  end

  def edit
    @event = Event.find(params.expect(:event_id))
    @team = Team.find(params.expect(:id))
  end

  def create
    @event = Event.find(params.expect(:event_id))
    @team = Team.new(team_params)
    @team.event = @event
    if @team.save
      apply_google_doc_brief(@team)
      redirect_to url_for([@event, @team])
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @event = Event.find(params.expect(:event_id))
    @team = Team.find(params.expect(:id))
    if @team.update(team_params)
      purge_marked_attachments(@team, :image, :brief)
      apply_google_doc_brief(@team)
      redirect_to url_for([@event, @team])
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event = Event.find(params.expect(:event_id))
    @team = Team.find(params.expect(:id))
    @team.destroy
    redirect_to action: 'index'
  end

  # Converting ONLY .docx files to .pdf
  def pdf
    team = Team.find(params.expect(:team_id))
    team.to_pdf
    redirect_to event_team_path(id: team.id), notice: 'The .docx files have been successfully converted to .pdf.',
                                              status: :see_other
  end

  # Private methods
  private

  # Generates the brief PDF from a pasted Google Doc link, if one was given.
  # URL format is validated on the model; only fetch/render failures land here.
  def apply_google_doc_brief(team)
    return if team.brief_url.blank?

    team.brief_from_google_doc(team.brief_url)
  rescue StandardError => e
    Rails.logger.error("Google Doc brief generation failed: #{e.class}: #{e.message}")
    flash[:alert] = "The brief could not be generated from that Google Doc link: #{e.message}"
  end

  def team_params
    keep_existing_files(params.expect(team: %i[name image brief brief_url remove_image remove_brief]),
                        :image, :brief)
  end
end
