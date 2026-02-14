# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Error pages', type: :request do
  describe '404 page', :error_page do
    it 'renders custom 404 for HTML' do
      get '/nonexistent_page_that_does_not_exist'
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('Error 404')
      expect(response.body).to include('The requested page was not found')
    end

    it 'renders custom 404 as JSON' do
      get '/nonexistent_page_that_does_not_exist', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq('error' => 'The requested page was not found')
    end
  end

  describe '422 page', :error_page do
    it 'renders custom 422 for HTML' do
      organiser = create(:organiser)
      event = create(:event, organiser_id: organiser.id)
      create(:organiser_to_event, organiser: organiser, event: event)
      login_as organiser

      allow(Event).to receive(:find).and_raise(ActionController::InvalidAuthenticityToken)

      get event_path(id: event.id)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Error 422')
    end
  end

  describe '500 page', :error_page do
    it 'renders custom 500 for HTML' do
      organiser = create(:organiser)
      event = create(:event, organiser_id: organiser.id)
      create(:organiser_to_event, organiser: organiser, event: event)
      login_as organiser

      # Stub a method to raise an error
      allow(Event).to receive(:find).and_raise(RuntimeError, 'test error')

      get event_path(id: event.id)
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include('Error 500')
    end

    it 'renders custom 500 as JSON' do
      organiser = create(:organiser)
      event = create(:event, organiser_id: organiser.id)
      create(:organiser_to_event, organiser: organiser, event: event)
      login_as organiser

      allow(Event).to receive(:find).and_raise(RuntimeError, 'test error')

      get event_path(id: event.id), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq('error' => 'Internal server error')
    end
  end
end
