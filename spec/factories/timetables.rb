# frozen_string_literal: true

# == Schema Information
#
# Table name: timetables
#
#  id          :bigint           not null, primary key
#  description :text
#  location    :string
#  time        :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  event_id    :bigint
#
# Indexes
#
#  index_timetables_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
FactoryBot.define do
  factory :timetable do
    event { nil }
    location { 'MyString' }
    time { '2025-03-06 14:23:32' }
    description { 'MyText' }
  end
end
