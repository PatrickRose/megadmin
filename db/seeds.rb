# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
#

o1 = Organiser.create(email: 'organiser1@email.com', password: 'testpw', name: 'organiser 1')
o2 = Organiser.create(email: 'organiser2@email.com', password: 'testpw', name: 'organiser 2')

5.times do |i|
  Event.create(name: "event #{i}",
               description: "event #{i}",
               date: Time.zone.now,
               location: 'location',
               additional_info: "additional_info for event #{i}",
               organiser_id: o1.id,
               draft: false)

  OrganiserToEvent.create(event_id: Event.find_by(name: "event #{i}").id,
                          organiser_id: o1.id, read_only: false)
  OrganiserToEvent.create(event_id: Event.find_by(name: "event #{i}").id,
                          organiser_id: o2.id, read_only: true, description: "control team for event #{i}")
end

5.times do |i|
  event = Event.find_by(name: "event #{i}")
  g1 = Team.create(name: "team 1 event #{i}", event_id: event.id)
  g2 = Team.create(name: "team 2 event #{i}", event_id: event.id)

  5.times do |j|
    role = Role.create(event_id: event.id,
                       team_id: g1.id,
                       name: "role #{j + 1} team 1 event #{i}")

    EventSignup.create(event_id: event.id,
                       role_id: role.id,
                       team_id: g1.id,
                       email: "team1role#{j + 1}@email.com",
                       name: "g1r#{j + 1}",
                       uuid: SecureRandom.uuid)
  end

  test_role = Role.create(event_id: event.id, name: "test #{i}")

  %w[Charlotte Alice Bob Edgar].each do |name|
    EventSignup.create(
      event_id: event.id,
      role_id: test_role,
      email: 'test@test.com',
      name: name,
      uuid: SecureRandom.uuid
    )
  end

  5.times do |j|
    role = Role.create(event_id: event.id,
                       team_id: g2.id,
                       name: "role #{j + 1} team 2 event #{i}")

    EventSignup.create(event_id: event.id,
                       role_id: role.id,
                       team_id: g2.id,
                       email: "team2role#{j + 1}@email.com",
                       name: "g2r#{j + 1}",
                       uuid: SecureRandom.uuid)
  end
end

Event.find_by(name: 'event 4')
