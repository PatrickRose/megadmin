# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Role destroy', type: :request do
  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event) }
  let!(:team) { create(:team, event: event) }
  let!(:role) { create(:role, name: 'Doomed role', event: event, team: team) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event, read_only: false)
    login_as organiser
  end

  it 'organiser can delete a role' do
    delete event_role_path(event_id: event.id, id: role.id)

    expect(response).to redirect_to(event_teams_path)
    expect(Role.find_by(id: role.id)).to be_nil
  end
end
