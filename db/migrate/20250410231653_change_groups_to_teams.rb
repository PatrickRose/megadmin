class ChangeGroupsToTeams < ActiveRecord::Migration[7.0]
  def change
    rename_table :groups, :teams
  end
end
