# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event do
  let(:event) { create(:event) }
  let(:team) { create(:team, event: event) }
  let(:role) { create(:role, event: event, team: team) }

  def attach_brief(record)
    record.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                        filename: 'pdf.pdf', content_type: 'application/pdf')
    record.save
  end

  describe '#signups_missing_assignment' do
    it 'includes signups without a role or team' do
      unassigned = create(:event_signup, event: event, email: 'a@a.com', team: nil, role: nil)
      create(:event_signup, event: event, email: 'b@b.com', team: team, role: role)

      expect(event.signups_missing_assignment).to contain_exactly(unassigned)
    end

    it 'is empty when every signup has a team and role' do
      create(:event_signup, event: event, email: 'b@b.com', team: team, role: role)

      expect(event.signups_missing_assignment).to be_empty
    end
  end

  describe '#teams_missing_briefs' do
    it 'includes assigned teams without a brief' do
      create(:event_signup, event: event, email: 'b@b.com', team: team, role: role)

      expect(event.teams_missing_briefs).to contain_exactly(team)
    end

    it 'excludes teams that have a brief attached' do
      attach_brief(team)
      create(:event_signup, event: event, email: 'b@b.com', team: team, role: role)

      expect(event.teams_missing_briefs).to be_empty
    end
  end

  describe '#roles_missing_briefs' do
    it 'includes assigned roles without a brief' do
      create(:event_signup, event: event, email: 'b@b.com', team: team, role: role)

      expect(event.roles_missing_briefs).to contain_exactly(role)
    end

    it 'excludes roles that have a brief attached even if the team has none' do
      attach_brief(role)
      create(:event_signup, event: event, email: 'b@b.com', team: team, role: role)

      expect(event.roles_missing_briefs).to be_empty
    end
  end
end
