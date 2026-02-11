# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id       :bigint           not null, primary key
#  name     :string
#  event_id :bigint
#
# Indexes
#
#  index_teams_on_event_id           (event_id)
#  index_teams_on_event_id_and_name  (event_id,name) UNIQUE
#  index_teams_on_name               (name)
#
FactoryBot.define do
  factory :team do
    name { 'Team one' }
  end
end
