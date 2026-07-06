# frozen_string_literal: true

# Records when a signup was last sent their brief email, for debugging duplicate/missing sends.
class AddBriefEmailedAtToEventSignups < ActiveRecord::Migration[7.1]
  def change
    add_column :event_signups, :brief_emailed_at, :datetime
  end
end
