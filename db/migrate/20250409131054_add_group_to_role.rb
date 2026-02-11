class AddGroupToRole < ActiveRecord::Migration[7.0]
  def change
    add_reference :roles, :group, null: false, foreign_key: true
  end
end
