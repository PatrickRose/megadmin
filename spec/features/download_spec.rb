# frozen_string_literal: true

require 'rails_helper'

context 'Downloading a zip file for a player' do
  before do
    organiser = Organiser.create!(email: 'organiser@email.com', password: 'password123',
                                  password_confirmation: 'password123', name: 'organiser')

    event = Event.create!(name: 'Test event', description: 'desc', location: 'location',
                          additional_info: 'info', date: DateTime.new(2026, 3, 15, 15, 0, 0),
                          organiser_id: organiser.id)

    @event_signup = EventSignup.create!(name: 'player', email: 'player@email.com',
                                        uuid: SecureRandom.uuid, event_id: event.id)
  end

  scenario 'player can download a zip of their documents' do
    visit download_path(@event_signup)

    expect(page.response_headers['Content-Type']).to eq 'application/zip'
    expect(page.response_headers['Content-Disposition']).to include('attachment')
    expect(page.response_headers['Content-Disposition']).to include('.zip')
  end
end

context 'Downloading a zip file for a player with team, briefs, and attachments' do
  before do
    organiser = Organiser.create!(email: 'organiser2@email.com', password: 'password123',
                                  password_confirmation: 'password123', name: 'organiser')

    @event = Event.create!(name: 'Test event', description: 'desc', location: 'location',
                           additional_info: 'info', date: DateTime.new(2026, 3, 15, 15, 0, 0),
                           organiser_id: organiser.id)

    @team = Team.create!(name: 'Alpha', event: @event)

    @role = Role.create!(name: 'Commander', event: @event, team: @team)

    @event_signup = EventSignup.create!(name: 'player', email: 'player2@email.com',
                                        uuid: SecureRandom.uuid, event_id: @event.id,
                                        team: @team, role: @role)
  end

  scenario 'zip includes team name in filename' do
    visit download_path(@event_signup)

    expect(page.response_headers['Content-Type']).to eq 'application/zip'
    expect(page.response_headers['Content-Disposition']).to include('team Alpha')
  end

  scenario 'zip includes role brief when attached' do
    @role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                       filename: 'pdf.pdf', content_type: 'application/pdf')
    @role.save

    visit download_path(@event_signup)

    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end

  scenario 'zip includes team brief when attached' do
    @team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                       filename: 'pdf.pdf', content_type: 'application/pdf')
    @team.save

    visit download_path(@event_signup)

    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end

  scenario 'zip includes rulebook when attached' do
    @event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                           filename: 'rulebook.pdf', content_type: 'application/pdf')
    @event.save

    visit download_path(@event_signup)

    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end

  scenario 'zip includes additional documents when attached' do
    @event.additional_documents.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                       filename: 'extra.pdf', content_type: 'application/pdf')
    @event.save

    visit download_path(@event_signup)

    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end
end
