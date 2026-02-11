class RemoveTimetableFromEvent < ActiveRecord::Migration[7.0]
  def change
    # oopsy daisy, sorry 🛌
    remove_column :events, :timetable, :text
  end
end
