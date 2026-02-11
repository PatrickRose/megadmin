class RemoveUniquenessFromRoleAndTeam < ActiveRecord::Migration[7.0]
  def change
      remove_index :roles, name: "index_roles_on_name"
      add_index :roles, :name, unique: false

      remove_index :teams, name: "index_teams_on_name"
      add_index :teams, :name, unique: false
  end
end
