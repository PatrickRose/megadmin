# frozen_string_literal: true

# Lets an organiser opt out of the team/role briefing-file checks on the send-email screen.
class AddSkipBriefValidationToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :skip_brief_validation, :boolean, default: false, null: false
  end
end
