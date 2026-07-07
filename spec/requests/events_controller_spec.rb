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

  describe 'show' do
    let!(:team) { create(:team, event: event) }
    let!(:role) { create(:role, event: event, team: team) }

    def attach_brief(record)
      record.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                          filename: 'pdf.pdf', content_type: 'application/pdf')
      record.save
    end

    it 'renders the event and its signups' do
      attach_brief(team)
      attach_brief(role)
      create(:event_signup, event: event, name: 'Ready player', email: 'ready@email.com',
                            team: team, role: role)

      get event_path(id: event.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(event.name)
      expect(response.body).to include('Send emails to all players')
      # Signup has a team, role, and both briefs, so every checklist item passes.
      expect(response.body).not_to include('✗')
    end

    it 'flags players with no role assigned on the checklist' do
      create(:event_signup, event: event, name: 'Roleless player', email: 'roleless@email.com')

      get event_path(id: event.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('✗ All roles assigned')
    end

    it 'flags missing team and role briefs separately on the checklist' do
      create(:event_signup, event: event, name: 'Briefless player', email: 'briefless@email.com',
                            team: team, role: role)

      get event_path(id: event.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('✗ All teams have briefing files')
      expect(response.body).to include('✗ All roles have briefing files')
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

  describe 'brief validation setting' do
    it 'shows the toggle on the edit page' do
      get edit_event_path(id: event.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('skip_brief_validation')
    end

    it 'persists the setting when the event is updated' do
      patch event_path(id: event.id),
            params: { event: { name: event.name, location: event.location,
                               date: event.date, google_maps_link: '', skip_brief_validation: '1' } }

      expect(event.reload.skip_brief_validation).to be true
    end
  end

  describe 'edit page' do
    it 'shows remove controls for existing attachments' do
      event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                            filename: 'rulebook.pdf', content_type: 'application/pdf')
      event.additional_documents.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                        filename: 'doc.pdf', content_type: 'application/pdf')

      get edit_event_path(id: event.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Remove current rulebook')
      expect(response.body).to include('remove_additional_document_ids')
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

    # Builds a signup that is valid to email: its own role (roles can only be
    # filled once per team) with a brief attached.
    def emailable_signup(name:, email:, brief_emailed_at: nil)
      role = create(:role, event: event, name: "role for #{name}", team: team)
      role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                        content_type: 'application/pdf')
      role.save
      create(:event_signup, event: event, name: name, email: email, role: role, team: team,
                            brief_emailed_at: brief_emailed_at)
    end

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

    it 'sends the brief email to each signup' do
      role1.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                         content_type: 'application/pdf')
      role1.save
      create(:event_signup, event: event, name: 'player1', email: 'p1@email.com',
                            role: role1, team: team)

      post email_event_path(id: event.id)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(response).to redirect_to(event_path(event_id: event.id))
    end

    it 'enqueues one brief email job per signup' do
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
      end.to have_enqueued_job(SendBriefEmailJob).exactly(11).times
    end

    it 'only emails players who have not been emailed yet by default' do
      emailable_signup(name: 'new', email: 'new@email.com')
      emailable_signup(name: 'already', email: 'already@email.com', brief_emailed_at: 1.day.ago)

      post email_event_path(id: event.id)

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.To.value).to eq('new@email.com')
    end

    it 'emails everyone when resend_all is set' do
      emailable_signup(name: 'new', email: 'new@email.com')
      emailable_signup(name: 'already', email: 'already@email.com', brief_emailed_at: 1.day.ago)

      post email_event_path(id: event.id), params: { resend_all: '1' }

      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end

    it 'tells the organiser when everyone has already been emailed' do
      emailable_signup(name: 'already', email: 'already@email.com', brief_emailed_at: 1.day.ago)

      post email_event_path(id: event.id)

      expect(response).to redirect_to(event_event_signups_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('All players have already been emailed')
    end
  end
end
