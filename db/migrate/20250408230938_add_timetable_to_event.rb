class AddTimetableToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :timetable, :text
  end
end
