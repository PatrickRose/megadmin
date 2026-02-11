class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.belongs_to  :event
      t.string      :role_name
    end
  end
end
