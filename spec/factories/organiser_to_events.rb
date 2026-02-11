# frozen_string_literal: true

# == Schema Information
#
# Table name: organiser_to_events
#
#  id           :bigint           not null, primary key
#  description  :string
#  read_only    :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  event_id     :bigint
#  organiser_id :bigint
#
# Indexes
#
#  index_organiser_to_events_on_event_id      (event_id)
#  index_organiser_to_events_on_organiser_id  (organiser_id)
#
FactoryBot.define do
  factory :organiser_to_event do
    read_only { false }
    event_id { 1 }
    organiser_id { 1 }
  end
end
