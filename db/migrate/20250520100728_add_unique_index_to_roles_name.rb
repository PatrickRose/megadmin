class AddUniqueIndexToRolesName < ActiveRecord::Migration[7.0]
  def change
    add_index :roles, [:name, :team_id], unique: true
  end
end
