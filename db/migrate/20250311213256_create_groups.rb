class CreateGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :groups do |t|
      t.belongs_to  :event
      t.string      :group_name
    end
  end
end
