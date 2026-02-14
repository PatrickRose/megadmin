# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventsController', type: :request do
  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event, organiser_id: organiser.id) }
  let!(:draft) { create(:event, draft: true, organiser_id: organiser.id) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event)
    create(:organiser_to_event, organiser: organiser, event: draft)
    login_as organiser
  end

  describe 'publish' do
    it 'renders edit on publish failure' do
      allow_any_instance_of(Event).to receive(:update).and_return(false)

      patch publish_event_path(id: draft.id)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'email' do
    let!(:team) { create(:team, event: event) }
    let!(:role1) { create(:role, event: event, name: 'email role 1', team: team) }

    it 'redirects with alert for draft event' do
      post email_event_path(id: draft.id)

      expect(response).to redirect_to(event_path(event_id: draft.id))
      follow_redirect!
      expect(response.body).to include('Event needs to be published to send emails')
    end

    it 'redirects with alert when signup is missing a role' do
      create(:event_signup, event: event, name: 'no role', email: 'norole@email.com')

      post email_event_path(id: event.id)

      expect(response).to redirect_to(event_event_signups_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('a signup is missing a role')
    end

    it 'redirects with alert when no signups exist' do
      post email_event_path(id: event.id)

      expect(response).to redirect_to(event_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('There are no signups to email')
    end

    it 'sends emails inline for <=10 signups' do
      role1.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                         content_type: 'application/pdf')
      role1.save
      create(:event_signup, event: event, name: 'player1', email: 'p1@email.com',
                            role: role1, team: team)

      post email_event_path(id: event.id)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(response).to redirect_to(event_path(event_id: event.id))
    end

    it 'uses background job for >10 signups' do
      ActiveJob::Base.queue_adapter = :test

      11.times do |i|
        r = create(:role, event: event, name: "bg role #{i}", team: team)
        r.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                       content_type: 'application/pdf')
        r.save
        create(:event_signup, event: event, name: "bgplayer#{i}", email: "bgp#{i}@email.com",
                              role: r, team: team)
      end

      expect {
        post email_event_path(id: event.id)
      }.to have_enqueued_job(SendEmailsJob)
    end
  end
end
