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

  def pdf_cast_list(view, event)
    html = html_cast_list(view, event)

    # https://github.com/Studiosity/grover?tab=readme-ov-file#relative-paths
    protocol = request.ssl? ? 'https' : 'http'
    absolute_html = Grover::HTMLPreprocessor.process(html, "#{protocol}://#{request.host_with_port}/", protocol)

    Grover.new(absolute_html, format: 'A4').to_pdf
  end

  def html_cast_list(view, event)
    @event = event

    # Group signups on teams, sort by signup name
    @grouped_event_signups = EventSignup.where(event_id: @event.id).group_by(&:team).map do |team, signups|
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
