# frozen_string_literal: true

# Controller for team management pages
class TeamsController < ApplicationController
  before_action :authenticate_organiser!
  load_and_authorize_resource

  # Public methods
  def index
    begin
      @event = Event.find(params[:event_id])
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
    @event = Event.find(params[:event_id])

    organiser = OrganiserToEvent.find_by(organiser_id: current_organiser.id, event_id: @event)
    @organiser = organiser.read_only

    @team = Team.find(params[:id])
  end

  def new
    @event = Event.find(params[:event_id])
    @team = Team.new
  end

  def edit
    @event = Event.find(params[:event_id])
    @team = Team.find(params[:id])
  end

  def create
    @event = Event.find(params[:event_id])
    @team = Team.new(team_params)
    @team.event = @event
    if @team.save
      redirect_to url_for([@event, @team])
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @event = Event.find(params[:event_id])
    @team = Team.find(params[:id])
    if @team.update(team_params)
      redirect_to url_for([@event, @team])
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event = Event.find(params[:event_id])
    @team = Team.find(params[:id])
    @team.destroy
    redirect_to action: 'index'
  end

  # Converting ONLY .docx files to .pdf
  def pdf
    team = Team.find(params[:team_id])
    team.to_pdf
    redirect_to event_team_path(id: team.id), notice: 'The .docx files have been successfully converted to .pdf.',
                                              status: :see_other
  end

  # Private methods
  private

  def team_params
    params.expect(team: %i[name image brief])
  end
end
