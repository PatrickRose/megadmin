class FixTeamsForeignKeys < ActiveRecord::Migration[7.0]
  def change
    rename_column :roles, :group_id, :team_id
    rename_column :event_signups, :group_id, :team_id
  end
end
