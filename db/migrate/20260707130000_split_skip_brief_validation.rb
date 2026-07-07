# frozen_string_literal: true

# Replaces the single skip_brief_validation flag with independent toggles for
# the team and role briefing-file checks on the send-email screen.
class SplitSkipBriefValidation < ActiveRecord::Migration[8.1]
  def change
    change_table :events, bulk: true do |t|
      t.boolean :skip_team_brief_validation, default: false, null: false
      t.boolean :skip_role_brief_validation, default: false, null: false
      t.remove :skip_brief_validation, type: :boolean, default: false, null: false
    end
  end
end
