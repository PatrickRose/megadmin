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
