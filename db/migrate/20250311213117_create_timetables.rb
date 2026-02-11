class CreateTimetables < ActiveRecord::Migration[7.0]
  def change
    create_table :timetables do |t|
      t.belongs_to  :event, foreign_key: true
      t.string      :location
      t.timestamp   :time
      t.text        :description

      t.timestamps
    end
  end
end
