# frozen_string_literal: true

# The organiser-facing cast list: adds an empty, tickable "Present" column so
# organisers can register attendance on a printed copy.
class OrganiserCastListPdf < CastListPdf
  PRESENT_COLUMN = 2
  PRESENT_COLUMN_WIDTH = 60

  private

  def signup_header
    %w[Name Role Present]
  end

  def signup_row(signup)
    [signup.name.to_s, signup.role&.name || 'Unassigned Role', '']
  end

  # Draw a visible box in the Present column so it can be ticked by hand.
  def style_signup_table(table)
    column = table.column(PRESENT_COLUMN)
    column.width = PRESENT_COLUMN_WIDTH
    column.borders = %i[top bottom left right]
    column.border_width = 0.5
  end
end
