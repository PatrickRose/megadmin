# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id       :bigint           not null, primary key
#  name     :string
#  event_id :bigint
#  team_id  :bigint           not null
#
# Indexes
#
#  index_roles_on_event_id          (event_id)
#  index_roles_on_name              (name)
#  index_roles_on_name_and_team_id  (name,team_id) UNIQUE
#  index_roles_on_team_id           (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

FactoryBot.define do
  factory :role do
    name { 'Important role' }
  end
end
