class UniqueNameTeamWithinEvent < ActiveRecord::Migration[7.0]
  def change
    add_index :teams, [:event_id, :name], unique: true
  end
end
