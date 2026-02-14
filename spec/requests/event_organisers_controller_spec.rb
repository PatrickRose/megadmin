# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventOrganisersController' do
  let!(:organiser1) { create(:organiser, email: 'email1@email.com') }
  let!(:organiser2) { create(:organiser, email: 'email2@email.com') }
  let!(:event) { create(:event, organiser_id: organiser1.id) }

  before do
    create(:organiser_to_event, event_id: event.id, organiser_id: organiser1.id)
  end

  describe 'create' do
    it 'redirects with alert on save failure' do
      login_as organiser1

      allow(OrganiserToEvent).to receive(:new).and_wrap_original do |method, *args|
        instance = method.call(*args)
        allow(instance).to receive(:save).and_return(false)
        instance
      end

      post event_event_organisers_path(event_id: event.id),
           params: { email: 'newsavedfail@email.com', read_only: false, description: 'test' }

      expect(response).to redirect_to(new_event_event_organiser_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('Organiser couldnt be added')
    end
  end

  describe 'update' do
    it 'control team cannot update another organiser' do
      ote2 = create(:organiser_to_event, event_id: event.id, organiser_id: organiser2.id)

      control = create(:organiser, email: 'control@email.com')
      create(:organiser_to_event, event_id: event.id, organiser_id: control.id, read_only: true)

      login_as control

      patch event_event_organiser_path(event_id: event.id, id: ote2.id),
            params: { organiser_to_event: { read_only: true, description: 'updated' } }

      expect(response).to redirect_to(event_event_organisers_path(event_id: event.id))
      follow_redirect!
      expect(response.body).to include('Cannot update')
    end

    it 'renders error on update failure' do
      ote2 = create(:organiser_to_event, event_id: event.id, organiser_id: organiser2.id)

      login_as organiser1

      allow(OrganiserToEvent).to receive(:find).and_wrap_original do |method, *args|
        instance = method.call(*args)
        allow(instance).to receive(:update).and_return(false)
        instance
      end

      patch event_event_organiser_path(event_id: event.id, id: ote2.id),
            params: { organiser_to_event: { read_only: true, description: 'updated' } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
