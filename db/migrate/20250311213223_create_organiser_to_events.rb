class CreateOrganiserToEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :organiser_to_events do |t|
      t.belongs_to  :event
      t.belongs_to  :organiser
      t.boolean     :read_only

      t.timestamps
    end
  end
end
