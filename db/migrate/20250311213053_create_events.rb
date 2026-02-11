class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string      :name
      t.text        :description
      t.text        :additional_info
      t.timestamp   :date
      t.references  :organiser, foreign_key: true
      t.string      :location
      t.string      :google_maps_link

      # t.has_many    :timetable
      # t.has_many    :additonal_document
      # t.has_many    :organiser, through: :organisers_to_events
      # t.has_many    :event_signup

      t.timestamps
    end
  end
end
