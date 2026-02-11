# frozen_string_literal: true

# Helper for event stuff
module EventsHelper
  def event_role(event, my_events, organiser_events)
    if my_events.map(&:id).include?(event.id)
      'Owner'
    elsif organiser_events.map(&:id).include?(event.id)
      'Organiser'
    else
      'Control Team'
    end
  end
end
