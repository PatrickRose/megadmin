class RenameNameInRoles < ActiveRecord::Migration[7.0]
  def change
    rename_column :roles, :role_name, :name
  end
end
