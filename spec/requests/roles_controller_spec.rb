# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RolesController' do
  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event, organiser_id: organiser.id) }
  let!(:team) { create(:team, event: event) }
  let!(:role) { create(:role, event: event, team: team) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event, read_only: false)
    login_as organiser
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                      filename: 'pdf.pdf', content_type: 'application/pdf')
  end

  describe 'update keeps the brief when the file field is left blank' do
    it 'keeps the brief when the brief field is blank' do
      patch event_role_path(event_id: event.id, id: role.id),
            params: { role: { name: 'Kept', brief: '', team_id: team.id } }

      expect(role.reload.brief).to be_attached
    end
  end
end
