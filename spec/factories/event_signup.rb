# frozen_string_literal: true

FactoryBot.define do
  factory :event_signup do
    name { 'Player one' }
    email { 'playerone@email.com' }
    uuid { SecureRandom.uuid }
  end
end
