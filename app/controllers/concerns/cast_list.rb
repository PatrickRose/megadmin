# frozen_string_literal: true

# Contains cast list generation code into a number of formats.
module CastList
  extend ActiveSupport::Concern

  def download_cast_list(view, event)
    pdf = pdf_cast_list(view, event)

    send_data pdf, filename: "#{event.formatted_name} Cast List.pdf",
                   type: 'application/pdf',
                   disposition: :attachment
  end

  # Streams the player cast list to the browser, reusing the cached PDF when
  # present (see #player_cast_list_pdf_bytes).
  def send_player_cast_list(event)
    send_data player_cast_list_pdf_bytes(event),
              filename: "#{event.formatted_name} Cast List.pdf",
              type: 'application/pdf',
              disposition: :attachment
  end

  # Returns the player cast list PDF bytes, generating and caching them on the
  # event on first use so we only launch Chromium once per event rather than
  # once per player download.
  def player_cast_list_pdf_bytes(event)
    return event.player_cast_list_pdf.download if event.player_cast_list_pdf.attached?

    regenerate_player_cast_list!(event)
  end

  # Re-renders the player cast list and (re)attaches it to the event, returning
  # the fresh PDF bytes. Called at email-send time and by the organiser's
  # "Regenerate cast list" button.
  def regenerate_player_cast_list!(event)
    pdf = pdf_cast_list('event_signups/player_cast_list', event)
    event.player_cast_list_pdf.attach(io: StringIO.new(pdf), filename: 'cast_list.pdf',
                                      content_type: 'application/pdf')
    pdf
  end

  def pdf_cast_list(view, event)
    html = html_cast_list(view, event)

    # https://github.com/Studiosity/grover?tab=readme-ov-file#relative-paths
    protocol = request.ssl? ? 'https' : 'http'
    absolute_html = Grover::HTMLPreprocessor.process(html, "#{protocol}://#{request.host_with_port}/", protocol)

    Grover.new(absolute_html, format: 'A4').to_pdf
  end

  def html_cast_list(view, event)
    @event = event

    # Group signups on teams, sort by signup name. Eager-load team and role so
    # grouping by team and rendering each signup's role doesn't fire a query per
    # signup (N+1).
    @grouped_event_signups = EventSignup.where(event_id: @event.id)
                                        .includes(:team, :role)
                                        .group_by(&:team).map do |team, signups|
      [team, signups.sort_by(&:name)]
    end

    # Get all organisers, control team and owner
    @owner = Organiser.find(@event.organiser_id)

    all_organisers = OrganiserToEvent.where(event_id: @event.id)

    # Exclude the owner from the organisers section, as they will be at the top
    @organisers = all_organisers.where(read_only: false).uniq.compact
    @organisers.reject! { |organiser| organiser == @owner }

    @control_team = all_organisers.where(read_only: true).uniq.compact

    # Render cast list using html template
    render_to_string({
                       template: view,
                       layout: 'cast_list'
                     })
  end
end
