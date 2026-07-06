# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TeamsController' do
  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event, organiser_id: organiser.id) }
  let!(:team) { create(:team, event: event) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event, read_only: false)
    login_as organiser
    team.image.attach(io: Rails.root.join('spec/fixtures/files/image.jpg').open,
                      filename: 'image.jpg', content_type: 'image/jpeg')
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                      filename: 'pdf.pdf', content_type: 'application/pdf')
  end

  describe 'update keeps attachments when file fields are left blank' do
    it 'keeps the icon when the image field is blank' do
      patch event_team_path(event_id: event.id, id: team.id),
            params: { team: { name: 'Kept', image: '', brief: '' } }

      expect(team.reload.image).to be_attached
    end

    it 'keeps the brief when the brief field is blank' do
      patch event_team_path(event_id: event.id, id: team.id),
            params: { team: { name: 'Kept', image: '', brief: '' } }

      expect(team.reload.brief).to be_attached
    end
  end
end
