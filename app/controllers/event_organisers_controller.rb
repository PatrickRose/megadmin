# frozen_string_literal: true

# Controller for event organiser management pages
class EventOrganisersController < ApplicationController
  before_action :authenticate_organiser!
  before_action :authorize_perms # custom authorisation

  def index
    @params = params
    @event = Event.find(params[:event_id])

    @ct = OrganiserToEvent.where(organiser_id: current_organiser.id, event_id: @event.id).first
    @control_team = @ct.read_only

    @organisers_to_events = OrganiserToEvent.where(event_id: params[:event_id])
  end

  def new
    @event = Event.find(params[:event_id])

    @ct = OrganiserToEvent.where(organiser_id: current_organiser.id, event_id: @event.id).first
    @control_team = @ct.read_only

    @event_organiser = OrganiserToEvent.new
    @event_organiser.event_id = params[:event_id]
  end

  def edit
    @event = Event.find(params[:event_id])
    @organiser_to_event = OrganiserToEvent.find(params[:id])
    @event = Event.find(params[:event_id])
  end

  def create
    # Refuse if email box blank
    if params[:email].blank?
      redirect_to new_event_event_organiser_path(event_id: params[:event_id]), alert: 'Email cannot be blank'
      return
    end

    @ct = OrganiserToEvent.where(organiser_id: current_organiser.id, event_id: @event.id).first
    @control_team = @ct.read_only

    organiser = Organiser.find_by(email: params[:email])

    if organiser.nil?
      # Creates new organiser with random password
      organiser = Organiser.new(email: params[:email], password: (0...8).map do
        rand(65..90).chr
      end.join, name: 'Organiser')
      organiser.save

      # Sends email to specified email with their password
      OrganiserMailer.organiser_email(organiser, Event.find(params[:event_id]), request.base_url).deliver
    end

    unless OrganiserToEvent.find_by(event_id: params[:event_id], organiser_id: organiser.id).nil?
      redirect_to new_event_event_organiser_path(event_id: params[:event_id]), alert: 'Organiser already assigned'
      return
    end

    @organiser_to_event = OrganiserToEvent.new
    # Ensure that control team can only add control team
    @organiser_to_event.read_only = if @control_team
                                      true
                                    else
                                      params[:read_only]
                                    end
    @organiser_to_event.event_id = params[:event_id]
    @organiser_to_event.description = params[:description]
    @organiser_to_event.organiser = organiser

    if @organiser_to_event.save
      redirect_to event_event_organisers_path(event_id: params[:event_id]), notice: 'Organiser added to event'
    else
      redirect_to new_event_event_organiser_path(event_id: params[:event_id]), alert: 'Organiser couldnt be added'
    end
    nil
  end

  def update
    @event = Event.find(params[:event_id])
    @organiser_to_event = OrganiserToEvent.find(params[:id])
    @ct = OrganiserToEvent.where(organiser_id: current_organiser.id, event_id: @event.id).first
    @control_team = @ct.read_only
    # Disallow control team edits, and edits to own account

    if !@control_team && (@organiser_to_event.organiser.id != current_organiser.id)
      if @organiser_to_event.update(read_only: params[:organiser_to_event][:read_only],
                                    description: params[:organiser_to_event][:description])
        redirect_to event_event_organisers_path(event_id: params[:event_id], notice: 'Successfully updated')
      else
        redirect_to edit_event_event_organiser_path(event_id: params[:event_id]), status: :unprocessable_entity
      end
    else
      redirect_to event_event_organisers_path(event_id: params[:event_id]), alert: 'Cannot update'
    end
  end

  def destroy
    organiser = OrganiserToEvent.find(params[:id])
    event = Event.find(organiser.event_id)

    # Prevent removing the event author
    if organiser.organiser_id == event.organiser_id
      redirect_to event_event_organisers_path(id: event.id), alert: 'Cannot remove event author from event'
      return
    end

    # Prevent removing yourself from an event
    if current_organiser.id == organiser.organiser_id
      redirect_to event_event_organisers_path(id: event.id), alert: 'Cannot remove yourself from event'
      return
    end

    organiser.destroy

    redirect_to event_event_organisers_path(id: event.id), notice: 'Organiser successfully removed from event',
                                                           status: :see_other
  end

  private

  def authorize_perms
    # Only allow organisers/control to manage organisers on event
    @event = Event.find(params[:event_id])
    authorize! :read, @event
  end

  def event_organiser_params
    params.require(:event_organiser).permit(:read_only, :email, :event_id)
  end
end
