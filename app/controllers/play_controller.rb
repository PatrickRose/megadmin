# frozen_string_literal: true

# Controller for player pages
class PlayController < ApplicationController
  def show
    # Get details of single player for specific event
    @single_event_signup = EventSignup.find_by(uuid: params[:id])

    # Get event details
    @play_event = @single_event_signup.event

    # Get all players for this event (needed for cast list)
    @all_event_signup = @play_event.event_signups

    # Get email of main event organiser
    @organiser_email = Organiser.find(@play_event.organiser_id).email

    # Get roles and teams that correspond with event
    @roles = Role.where(event_id: @play_event.id)
    @teams = Team.where(event_id: @play_event.id)

    @cast_list = html_cast_list('event_signups/player_page_cast_list', @play_event)

    # Google maps link in format <iframe src="[link]".....
    # Need to get [link] between two " if link isn't empty
    unless @play_event.google_maps_link.nil?
      @first_index = @play_event.google_maps_link.index('"')
      unless @first_index.nil?
        @second_index = @play_event.google_maps_link[@first_index..].index('"', @first_index + 1)
        @just_link = @play_event.google_maps_link[@first_index + 1, @second_index - 1]
      end
    end

    # Gets number of days until event
    # [0, 11] takes date portion of datetime - eg "2025-04-11 17:23:32 +0100" => "2025-04-11"
    # Date_difference in format "x/1"
    @date_difference = (Date.parse(@play_event.date.to_s[0, 11]) - Time.zone.today).to_s
    # Number is date_difference without "/1" eg @date_difference = "27/1" @number = 27
    @number = @date_difference[0..@date_difference.index('/') - 1].to_i
  end

  # For downloading cast list from player's page, might not be needed atm
  # Visit here /play/:id/player_cast_list
  include CastList

  def player_cast_list
    if params[:id].blank?
      redirect_to root_path, alert: 'Missing player UUID.', status: :see_other
      return
    end

    event_signup = EventSignup.find_by(uuid: params[:id])
    if event_signup.nil?
      redirect_to root_path, alert: 'Player not found.', status: :see_other
      return
    end

    event = event_signup.event

    download_cast_list('event_signups/player_cast_list', event)
  end

  private

  def event_params
    params.require(:event).permit(:name, :description, :location, :google_maps_link, :date, :timetable,
                                  :additional_info)
  end
end
