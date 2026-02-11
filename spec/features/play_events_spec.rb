# frozen_string_literal: true

require 'rails_helper'

context 'Viewing the player page' do
  before do
    @organiser1 = Organiser.create!(email: 'organiser1@email.com', password: 'password123',
                                    password_confirmation: 'password123', name: 'organiser name')

    @event1 = Event.create!(id: 1, name: 'Test event', description: 'desc', location: 'location',
                            additional_info: 'additional info', date: DateTime.new(2026, 0o3, 15, 15, 31, 0o0),
                            created_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536),
                            updated_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536), organiser_id: @organiser1.id,
                            google_maps_link: '<iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d' \
                                              '10556.00759592474!2d-1.4843440274419275!3d53.37847046477475!2m3!1f0' \
                                              '!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x48797881e28b3e81%3A0x6' \
                                              '11c9522ca2169ed!2sThe%20Diamond!5e1!3m2!1sen!2suk!4v1747943995459!5' \
                                              'm2!1sen!2suk" width="600" height="450" ' \
                                              'style="border:0;" allowfullscreen=""loading="lazy"' \
                                              'referrerpolicy="no-referrer-when-downgrade"></iframe>')

    @event_signup1 = EventSignup.create(name: 'name', email: 'email1@email.com', uuid: SecureRandom.uuid,
                                        event_id: 1, created_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536),
                                        updated_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536))

    @event_signup2 = EventSignup.create(name: 'name', email: 'email2@email.com', uuid: SecureRandom.uuid,
                                        event_id: 2, created_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536),
                                        updated_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536))

    @event_signup3 = EventSignup.create!(name: 'name2', role_id: 1, team_id: 1, email: 'email3@email.com',
                                         uuid: SecureRandom.uuid,
                                         event_id: 1, created_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536),
                                         updated_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536))

    @event_docs = Event.create!(id: 2, name: 'Test with docs', description: 'desc', location: 'location',
                                additional_info: 'additional info', date: DateTime.new(2026, 0o3, 15, 15, 31, 0o0),
                                created_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536),
                                updated_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536),
                                organiser_id: @organiser1.id)
    @event_docs.additional_documents.attach([{ io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                               filename: 'pdf.pdf',
                                               content_type: 'application/pdf' },
                                             { io: Rails.root.join('spec/fixtures/files/doc.doc').open,
                                               filename: 'doc.doc',
                                               content_type: 'application/msword' }])
    @event_docs.save

    @event_signup4 = EventSignup.create!(name: 'name3', role_id: 2, team_id: 1, email: 'email4@email.com',
                                         uuid: SecureRandom.uuid,
                                         event_id: 2, created_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536),
                                         updated_at: DateTime.new(2025, 0o3, 14, 15, 35, 13, 455_536))
  end

  scenario "I can view an event's basic information (name, date, location, etc)" do
    visit "/play/#{@event_signup1.uuid}"
    expect(page).to have_content 'Test event'
    expect(page).to have_content 'desc'
    expect(page).to have_content 'location'
    expect(page).to have_content 'additional info'
    expect(page).to have_content 'Sunday 15th March 2026'
    expect(page).to have_css('iframe[src^="https://www.google.com/maps/embed?pb="]')
  end

  scenario 'There will be a note if roles and teams are not yet assigned' do
    visit "/play/#{@event_signup1.uuid}"

    expect(page).to have_content "Your team and role haven't yet been assigned"
  end

  scenario 'Player can see their role and team if assigned' do
    t = Team.create(id: 1, event_id: 1, name: 'Team')
    Role.create(id: 1, event_id: 1, name: 'Role', team: t)

    visit "/play/#{@event_signup3.uuid}"

    expect(page).to have_content "You'll be on the team 'Team'"
    expect(page).to have_content "Your individual role will be 'Role'"
  end

  scenario 'Player can see their name and email on the page to confirm they are on the right page' do
    visit "/play/#{@event_signup1.uuid}"
    expect(page).to have_content 'Game brief for name'
    expect(page).to have_content '(email1@email.com)'
  end

  scenario 'Players can see the roles and teams of all players' do
    t = Team.create(id: 1, event_id: 1, name: 'Team')
    Role.create(id: 1, event_id: 1, name: 'Role', team: t)
    visit "/play/#{@event_signup1.uuid}"
    expect(page).to have_content 'Name'
    expect(page).to have_content 'name'
    expect(page).to have_content 'Unassigned Team'
    expect(page).to have_content 'Unassigned Role'
    expect(page).to have_content 'Team'
    expect(page).to have_content 'name2'
    expect(page).to have_content 'Role'
  end

  scenario 'Players can see additional documents' do
    visit "/play/#{@event_signup4.uuid}"
    expect(page).to have_content 'pdf.pdf'
    expect(page).to have_content 'doc.doc'
    expect(page).to have_content 'This document is not a .pdf file and cannot be previewed.'
    expect(page).to have_css('#doc-preview')
    expect(page).to have_no_content 'There are no additional documents.'
  end

  scenario 'There will be a note if no additional documents are attached' do
    visit "/play/#{@event_signup1.uuid}"
    expect(page).to have_content 'There are no additional documents.'
    expect(page).to have_no_css('#doc-preview')
    expect(page).to have_no_content 'pdf.pdf'
    expect(page).to have_no_content 'doc.doc'
  end

  scenario 'There will be an error if uuid is blank when downloading cast list' do
    visit 'play/%20/player_cast_list'
    expect(page).to have_current_path(root_path)
    expect(page).to have_content('Missing player UUID.')
  end

  scenario 'There will be an error if uuid is nil when downloading cast list' do
    visit 'play/invalid_uuid/player_cast_list'
    expect(page).to have_current_path(root_path)
    expect(page).to have_content('Player not found.')
  end

  scenario 'download_cast_list called correctly with correct params' do
    visit "play/#{@event_signup1.uuid}/player_cast_list"
    expect(page.response_headers['Content-Disposition']).to include('attachment')
  end
end
