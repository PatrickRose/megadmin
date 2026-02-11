class RenameNameInGroups < ActiveRecord::Migration[7.0]
  def change
    rename_column :groups, :group_name, :name
  end
end
