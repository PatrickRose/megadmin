# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Generate template csv for event' do
  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event) }
  let!(:team) { create(:team, event: event) }
  let!(:role1) { create(:role, name: 'role 1', team: team, event: event) }
  let!(:role2) { create(:role, name: 'role 2', team: team, event: event) }
  let!(:role3) { create(:role, name: 'role 3', team: team, event: event) }
  let!(:role4) { create(:role, name: 'role 4', team: team, event: event) }

  before do
    create(:event_signup, name: 'Fred', event: event, team: team, role: role1)
    create(:organiser_to_event, organiser_id: organiser.id, event_id: event.id, read_only: false)
  end

  scenario 'I can see all unassigned roles in the template csv', type: :request do
    login_as organiser

    get generate_template_event_event_signups_path(event)

    csv_file = response.body
    csv = CSV.parse(csv_file, headers: true)

    expected_rows = [
      { 'name' => nil, 'email' => nil, 'team' => team.name, 'role' => role2.name },
      { 'name' => nil, 'email' => nil, 'team' => team.name, 'role' => role3.name },
      { 'name' => nil, 'email' => nil, 'team' => team.name, 'role' => role4.name }
    ]

    actual_rows = csv.map(&:to_h)

    expect(actual_rows).to eq(expected_rows)
  end
end
