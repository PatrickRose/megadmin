class CreateEventSignups < ActiveRecord::Migration[7.0]
  def change
    create_table :event_signups do |t|
      t.belongs_to  :event
      t.belongs_to  :role
      t.belongs_to  :group
      t.string      :email
      t.string      :name

      t.timestamps
    end
  end
end
