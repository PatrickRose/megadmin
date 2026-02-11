class AddUniqueToGroupRole < ActiveRecord::Migration[7.0]
  def change
    add_index :groups, :name, unique: true
    add_index :roles, :name, unique: true
  end
end
