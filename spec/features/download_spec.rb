# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Downloading a zip file for a player' do
  context 'with no team or attachments' do
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

  context 'with team, briefs, and attachments' do
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

    scenario 'streams attachment content into the zip (backend-agnostic, no path_for)' do
      @role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                         filename: 'pdf.pdf', content_type: 'application/pdf')
      @role.save
      # The cast list render is irrelevant here; stub it to avoid launching Chromium.
      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: 'FAKE-PDF-BYTES'))

      visit download_path(@event_signup)

      expect(page.response_headers['Content-Type']).to eq 'application/zip'

      # The brief is added by downloading the blob (works on Azure Blob, which
      # has no path_for), so its bytes must round-trip into the zip.
      brief_bytes = Rails.root.join('spec/fixtures/files/pdf.pdf').binread
      Zip::File.open_buffer(StringIO.new(page.body)) do |zip|
        entry = zip.find { |e| e.name.include?('role brief') }
        expect(entry).not_to be_nil
        expect(entry.get_input_stream.read).to eq(brief_bytes)
      end
    end
  end

  context 'cast list caching' do
    before do
      organiser = Organiser.create!(email: 'organiser3@email.com', password: 'password123',
                                    password_confirmation: 'password123', name: 'organiser')

      @event = Event.create!(name: 'Test event', description: 'desc', location: 'location',
                             additional_info: 'info', date: DateTime.new(2026, 3, 15, 15, 0, 0),
                             organiser_id: organiser.id)

      @event_signup = EventSignup.create!(name: 'player', email: 'player3@email.com',
                                          uuid: SecureRandom.uuid, event_id: @event.id)
    end

    scenario 'generates and caches the player cast list on first download' do
      # Stub the Grover (Chromium) render so the test doesn't launch a browser.
      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: 'FAKE-PDF-BYTES'))

      expect { visit download_path(@event_signup) }
        .to change { @event.reload.player_cast_list_pdf.attached? }.from(false).to(true)

      expect(Grover).to have_received(:new).once
    end

    scenario 'reuses the cached cast list without launching Chromium again' do
      @event.player_cast_list_pdf.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                         filename: 'cast_list.pdf', content_type: 'application/pdf')
      @event.save

      allow(Grover).to receive(:new)

      visit download_path(@event_signup)

      expect(page.response_headers['Content-Type']).to eq 'application/zip'
      expect(Grover).not_to have_received(:new)
    end
  end
end
