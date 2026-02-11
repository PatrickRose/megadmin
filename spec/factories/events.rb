# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id               :bigint           not null, primary key
#  additional_info  :text
#  date             :datetime
#  description      :text
#  draft            :boolean
#  google_maps_link :string
#  location         :string
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organiser_id     :bigint
#
# Indexes
#
#  index_events_on_organiser_id  (organiser_id)
#
# Foreign Keys
#
#  fk_rails_...  (organiser_id => organisers.id)
#
FactoryBot.define do
  factory :event do
    name { 'My Event' }
    description { 'Hello' }
    location { 'The location' }
    date { '2025-03-06 14:19:27' }
  end
end
