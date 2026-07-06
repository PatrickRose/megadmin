# frozen_string_literal: true

# Controller for roles pages
class RolesController < ApplicationController
  before_action :authenticate_organiser!
  load_and_authorize_resource

  # Public methods
  def show
    @event = Event.find(params.expect(:event_id))
    @role = Role.find(params.expect(:id))
    @team = @role.team_id

    o = OrganiserToEvent.find_by(organiser_id: current_organiser.id, event_id: @event)
    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) if o.nil?

    @organiser = o.read_only
  end

  def new
    @event = Event.find(params.expect(:event_id))
    @teams = @event.teams
    @role = Role.new
  end

  def edit
    @event = Event.find(params.expect(:event_id))
    @role = Role.find(params.expect(:id))
  end

  def create
    @event = Event.find(params.expect(:event_id))
    @role = Role.new(role_params)
    @role.team = Team.find_by(id: role_params[:team_id], event_id: params[:event_id])
    @role.event = @event
    if @role.save
      apply_google_doc_brief(@role)
      redirect_to url_for([@event, @role])
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @event = Event.find(params.expect(:event_id))
    @role = Role.find(params.expect(:id))
    if @role.update(role_params)
      apply_google_doc_brief(@role)
      redirect_to url_for([@event, @role])
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event = Event.find(params.expect(:event_id))
    @role = Role.find(params.expect(:id))
    @role.destroy
    redirect_to event_teams_path
  end

  # Converting ONLY .docx files to .pdf
  def pdf
    role = Role.find(params.expect(:role_id))
    role.to_pdf
    redirect_to event_role_path(id: role.id), notice: 'The .docx files have been successfully converted to .pdf.',
                                              status: :see_other
  end

  # Private methods
  private

  # Generates the brief PDF from a pasted Google Doc link, if one was given.
  # URL format is validated on the model; only fetch/render failures land here.
  def apply_google_doc_brief(role)
    return if role.brief_url.blank?

    role.brief_from_google_doc(role.brief_url)
  rescue StandardError => e
    Rails.logger.error("Google Doc brief generation failed: #{e.class}: #{e.message}")
    flash[:alert] = "The brief could not be generated from that Google Doc link: #{e.message}"
  end

  def role_params
    params.expect(role: %i[name brief team_id brief_url])
  end
end
