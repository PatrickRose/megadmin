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
    before do
      # Stub the Grover (Chromium) render used when caching the cast list.
      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: 'FAKE-PDF-BYTES'))
    end

    # Builds a signup that is valid to email: its own role with a brief attached.
    def emailable_signup(name:, email:, brief_emailed_at: nil)
      role = create(:role, event: event, name: "role for #{name}", team: team)
      role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                        content_type: 'application/pdf')
      role.save
      create(:event_signup, event: event, name: name, email: email, role: role, team: team,
                            brief_emailed_at: brief_emailed_at)
    end

    it 'regenerates the cached cast list when emailing all signups' do
      emailable_signup(name: 'roster', email: 'roster@email.com')

      expect { post email_event_event_signups_path(event_id: event.id) }
        .to change { event.reload.player_cast_list_pdf.attached? }.from(false).to(true)
    end

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

    it 'enqueues one brief email job per signup' do
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
      end.to have_enqueued_job(SendBriefEmailJob).exactly(11).times
    end

    it 'only emails players who have not been emailed yet by default' do
      emailable_signup(name: 'new', email: 'new@email.com')
      emailable_signup(name: 'already', email: 'already@email.com', brief_emailed_at: 1.day.ago)

      post email_event_event_signups_path(event_id: event.id)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.To.value).to eq('new@email.com')
    end

    it 'tells the organiser when everyone has already been emailed' do
      emailable_signup(name: 'already', email: 'already@email.com', brief_emailed_at: 1.day.ago)

      post email_event_event_signups_path(event_id: event.id)

      expect(response).to redirect_to(event_event_signups_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('All players have already been emailed')
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

  describe 'regenerate_cast_list' do
    before do
      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: 'FAKE-PDF-BYTES'))
    end

    it 'regenerates and caches the player cast list PDF' do
      expect { post regenerate_cast_list_event_event_signups_path(event_id: event.id) }
        .to change { event.reload.player_cast_list_pdf.attached? }.from(false).to(true)

      expect(response).to redirect_to(event_event_signups_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('Cast list regenerated')
    end
  end
end
