# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventSignupsController' do
  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event, organiser_id: organiser.id) }
  let!(:draft) { create(:event, organiser_id: organiser.id, draft: true) }
  let!(:team) { create(:team, event: event) }

  before do
    event.organisers << organiser
    draft.organisers << organiser
    create(:organiser_to_event, event_id: event.id, organiser_id: organiser.id)
    create(:organiser_to_event, event_id: draft.id, organiser_id: organiser.id)
    login_as organiser
  end

  describe 'email' do
    it 'redirects with alert for draft event' do
      create(:event_signup, event: draft, name: 'draft signup', email: 'draft@email.com')

      post email_event_event_signups_path(event_id: draft.id)

      expect(response).to redirect_to(event_event_signups_path(event_id: draft.id))
      follow_redirect!
      expect(response.body).to include('Event needs to be published to send emails')
    end

    it 'redirects with alert when no signups exist' do
      post email_event_event_signups_path(event_id: event.id)

      expect(response).to redirect_to(event_event_signups_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('There are no signups to email')
    end

    it 'uses background job for >10 signups' do
      ActiveJob::Base.queue_adapter = :test

      11.times do |i|
        r = create(:role, event: event, name: "extra role #{i}", team: team)
        r.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                       content_type: 'application/pdf')
        r.save
        create(:event_signup, event: event, name: "extra #{i}", email: "extra#{i}@email.com",
                              role: r, team: team)
      end

      expect do
        post email_event_event_signups_path(event_id: event.id)
      end.to have_enqueued_job(SendEmailsJob)
    end
  end

  describe 'email_single' do
    it 'redirects with alert for draft event' do
      signup = create(:event_signup, event: draft, name: 'draft signup', email: 'draftsingle@email.com')

      post email_single_event_event_signups_path(event_id: draft.id), params: { id: signup.id }

      expect(response).to redirect_to(event_event_signups_path(event_id: draft.id))
      follow_redirect!
      expect(response.body).to include('Event needs to be published to send emails')
    end
  end
end
