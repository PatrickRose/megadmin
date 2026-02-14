# frozen_string_literal: true

# Controller for roles pages
class RolesController < ApplicationController
  before_action :authenticate_organiser!
  load_and_authorize_resource

  # Public methods
  def show
    @event = Event.find(params[:event_id])
    @role = Role.find(params[:id])
    @team = @role.team_id

    o = OrganiserToEvent.where(organiser_id: current_organiser.id, event_id: @event)
    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) if o.first.nil?

    @organiser = o.first.read_only
  end

  def new
    @event = Event.find(params[:event_id])
    @teams = @event.teams
    @role = Role.new
  end

  def edit
    @event = Event.find(params[:event_id])
    @role = Role.find(params[:id])
  end

  def create
    @event = Event.find(params[:event_id])
    @role = Role.new(role_params)
    @role.team = Team.where(id: role_params[:team_id], event_id: params[:event_id]).first
    @role.event = @event
    if @role.save
      redirect_to url_for([@event, @role])
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @event = Event.find(params[:event_id])
    @role = Role.find(params[:id])
    if @role.update(role_params)
      redirect_to url_for([@event, @role])
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event = Event.find(params[:event_id])
    @role = Role.find(params[:id])
    @role.destroy
    redirect_to event_teams_path
  end

  # Converting ONLY .docx files to .pdf
  def pdf
    role = Role.find(params[:role_id])
    role.to_pdf
    redirect_to event_role_path(id: role.id), notice: 'The .docx files have been successfully converted to .pdf.',
                                              status: :see_other
  end

  # Private methods
  private

  def role_params
    params.require(:role).permit(:name, :brief, :team_id)
  end
end
