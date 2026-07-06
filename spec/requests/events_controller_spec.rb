# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventsController' do
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
      allow(Event).to receive(:find).and_wrap_original do |method, *args|
        instance = method.call(*args)
        allow(instance).to receive(:update).and_return(false) if instance.id == draft.id
        instance
      end

      patch publish_event_path(id: draft.id)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'update keeps attachments when file fields are left blank' do
    it 'keeps the rulebook when the rulebook field is blank' do
      event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                            filename: 'rulebook.pdf', content_type: 'application/pdf')

      patch event_path(id: event.id),
            params: { event: { name: event.name, location: event.location,
                               date: event.date, google_maps_link: '', rulebook: '' } }

      expect(event.reload.rulebook).to be_attached
    end

    it 'keeps additional documents when the field is blank' do
      2.times do |i|
        event.additional_documents.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                          filename: "doc#{i}.pdf", content_type: 'application/pdf')
      end

      patch event_path(id: event.id),
            params: { event: { name: event.name, location: event.location,
                               date: event.date, google_maps_link: '', additional_documents: [''] } }

      expect(event.reload.additional_documents.count).to eq(2)
    end
  end

  describe 'update can remove attachments' do
    it 'removes the rulebook when remove_rulebook is checked' do
      event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                            filename: 'rulebook.pdf', content_type: 'application/pdf')

      patch event_path(id: event.id),
            params: { event: { name: event.name, location: event.location, date: event.date,
                               google_maps_link: '', rulebook: '', remove_rulebook: '1' } }

      expect(event.reload.rulebook).not_to be_attached
    end

    it 'removes only the selected additional document' do
      2.times do |i|
        event.additional_documents.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                          filename: "doc#{i}.pdf", content_type: 'application/pdf')
      end
      target = event.additional_documents.first

      patch event_path(id: event.id),
            params: { event: { name: event.name, location: event.location, date: event.date,
                               google_maps_link: '', additional_documents: [''],
                               remove_additional_document_ids: [target.id] } }

      event.reload
      expect(event.additional_documents.count).to eq(1)
      expect(event.additional_documents.map(&:id)).not_to include(target.id)
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

      expect do
        post email_event_path(id: event.id)
      end.to have_enqueued_job(SendEmailsJob)
    end
  end
end
