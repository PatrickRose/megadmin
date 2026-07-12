# frozen_string_literal: true

# Renders an event's cast list as a PDF using Prawn (pure Ruby, no headless
# browser). This replaces the Grover/Chromium HTML->PDF path for cast lists: the
# content is plain tabular data we control, so it needs no browser, no external
# CSS/fonts, and only a few MB of memory. See CastList#regenerate_player_cast_list!.
#
# Deliberately takes only an Event (no controller/request), so it can be rendered
# outside a web request — e.g. from a background job.
#
# Subclasses tailor the per-player table (see PlayerCastListPdf and
# OrganiserCastListPdf) by overriding the signup column hooks.
class CastListPdf
  # No cell borders, alternating row shading, comfortable padding.
  TABLE_OPTIONS = {
    width: 523,
    header: true,
    row_colors: %w[F2F2F2 FFFFFF],
    cell_style: { borders: [], padding: [4, 6] }
  }.freeze

  def initialize(event)
    @event = event
  end

  # Returns the rendered PDF as a binary string.
  def render
    document = Prawn::Document.new(page_size: 'A4')

    heading(document, @event.formatted_name, size: 24)
    owner_section(document)
    organisers_section(document)
    control_team_section(document)
    teams_section(document)

    document.render
  end

  private

  # ----- per-player table shape: overridden by subclasses -----

  def signup_header
    %w[Name Role]
  end

  def signup_row(signup)
    [signup.name.to_s, signup.role&.name || 'Unassigned Role']
  end

  # Hook for subclasses to add per-column styling to a signup table.
  def style_signup_table(table); end

  # ----- shared sections -----

  def owner
    @owner ||= Organiser.find(@event.organiser_id)
  end

  # The event's organiser links, eager-loaded so rendering names doesn't N+1.
  def organiser_links
    @organiser_links ||= OrganiserToEvent.where(event_id: @event.id).includes(:organiser).to_a
  end

  def owner_section(document)
    heading(document, 'Owner', size: 16)
    document.text owner.name.to_s
    document.move_down 12
  end

  def organisers_section(document)
    # Editors (read/write) other than the owner, who is shown separately above.
    rows = organiser_links.reject(&:read_only?).reject { |link| link.organiser_id == owner.id }
    return if rows.empty?

    heading(document, 'Organisers', size: 16)
    person_table(document, rows)
  end

  def control_team_section(document)
    rows = organiser_links.select(&:read_only?)
    return if rows.empty?

    heading(document, 'Control Team', size: 16)
    person_table(document, rows)
  end

  def teams_section(document)
    grouped = EventSignup.where(event_id: @event.id).includes(:team, :role).group_by(&:team)

    if grouped.empty?
      document.text 'There are no players in this event.'
      return
    end

    grouped.each do |team, signups|
      heading(document, team&.name || 'Unassigned Team', size: 16)
      signup_table(document, signups.sort_by(&:name))
    end
  end

  def person_table(document, links)
    rows = [%w[Name Description]] + links.map { |link| [link.organiser.name.to_s, link.description.to_s] }
    styled_table(document, rows)
  end

  def signup_table(document, signups)
    if signups.empty?
      document.text 'There are no players in this team.'
      document.move_down 12
      return
    end

    rows = [signup_header] + signups.map { |signup| signup_row(signup) }
    styled_table(document, rows) { |table| style_signup_table(table) }
  end

  def styled_table(document, rows)
    document.table(rows, TABLE_OPTIONS) do |table|
      table.row(0).font_style = :bold
      yield table if block_given?
    end
    document.move_down 12
  end

  def heading(document, text, size:)
    document.text text, size: size, style: :bold
    document.move_down 6
  end
end
