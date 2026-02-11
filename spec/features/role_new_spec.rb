# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Role new page' do
  # Setup

  let!(:organiser) { create(:organiser) }
  let!(:event) { create(:event) }
  let!(:team) { create(:team, event: event) }
  let!(:team2) { create(:team, name: 'Team 2', event: event) }

  before do
    create(:role, name: 'ABCD', team: team2, event: event)
    create(:organiser_to_event, organiser_id: organiser.id, event_id: event.id, read_only: false)
  end

  after do
    OrganiserToEvent.delete_all
  end

  # Tests
  context 'as an organiser' do
    before do
      login_as(organiser, scope: :organiser)
    end

    context 'for a valid event' do
      scenario 'user can access the create role page' do
        visit new_event_role_path(event_id: event.id)
        expect(page).to have_content 'Create a Role'
      end

      scenario 'user can create a new role with valid paramaters' do
        visit new_event_role_path(event_id: event.id)
        fill_in 'role_name', with: 'Test role'
        attach_file('role_brief', Rails.root.join('spec/fixtures/files/pdf.pdf'))
        select team.name, from: 'role_team_id'
        click_on 'commit'
        expect(page).to have_content 'Test role'
      end

      scenario 'user cannot create a new role with blank name' do
        visit new_event_role_path(event_id: event.id)
        fill_in 'role_name', with: '   '
        click_on 'commit'
        expect(page).to have_content "Name can't be blank"
      end

      scenario 'user cannot create a new role with non-unique name in its team' do
        visit new_event_role_path(event_id: event.id)
        fill_in 'role_name', with: 'ABCD'
        select team2.name, from: 'role_team_id'
        click_on 'commit'
        expect(page).to have_content 'Name must be unique within a team.'
      end

      scenario 'user cannot attach an invalid filetype to the brief upload field' do
        visit new_event_role_path(event_id: event.id)
        fill_in 'role_name', with: 'Test role'
        attach_file('role_brief', Rails.root.join('spec/fixtures/files/text.txt'))
        click_on 'commit'
        expect(page).to have_content 'Brief has an invalid content type'
      end

      scenario 'user can go back to view all teams and roles' do
        visit new_event_role_path(event_id: event.id)
        find_by_id('nav-bar').click_on('Manage Teams')
        expect(page).to have_current_path(event_teams_path(event_id: event.id))
      end
    end

    context 'for an invalid event' do
      scenario 'user is shown the error message' do
        visit new_event_role_path(event_id: 9_999_999)
        expect(page).to have_content 'Event could not be found'
      end
    end
  end

  context 'as the control team' do
    before do
      OrganiserToEvent.find_by(organiser_id: organiser.id, event_id: event.id)&.update(read_only: true)
      login_as(organiser, scope: :organiser)
    end

    context 'for a valid event' do
      scenario 'user CANNOT access the create role page' do
        visit new_event_role_path(event_id: event.id)

        expect(page).to have_content 'You are not authorised to access this page'
      end
    end

    context 'for an invalid event' do
      scenario 'user is shown the error message' do
        visit new_event_role_path(event_id: 9_999_999)

        expect(page).to have_content 'Event could not be found'
      end
    end
  end
end
