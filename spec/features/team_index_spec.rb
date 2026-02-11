# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Team index page' do
  # Setup
  let!(:organiser) { create(:organiser) }
  let!(:team) { create(:team, name: 'Test team 1', event: event_teams) }

  let!(:event_teams) { create(:event, organiser_id: organiser.id) }

  let!(:event_no_teams) { create(:event, organiser_id: organiser.id) }

  before do
    create(:organiser_to_event, organiser_id: organiser.id, event_id: event_teams.id, read_only: false)
    create(:organiser_to_event, organiser_id: organiser.id, event_id: event_no_teams.id, read_only: false)
  end

  after do
    OrganiserToEvent.delete_all
  end

  # Tests
  context 'as an organiser' do
    before do
      login_as(organiser, scope: :organiser)
    end

    context 'for a valid event with teams' do
      scenario 'user sees the teams' do
        visit event_teams_path(event_id: event_teams.id)

        expect(page).to have_content 'Test team 1'
        expect(page).to have_no_content 'No teams found for the game'
      end

      scenario 'user can go to a new team page' do
        visit event_teams_path(event_id: event_teams.id)

        find_by_id('nav-bar').click_on('New Team')
        expect(page).to have_current_path(new_event_team_path(event_id: event_teams.id))
      end

      scenario 'user can go to a show page for a team' do
        visit event_teams_path(event_id: event_teams.id)

        click_on 'Test team 1'
        expect(page).to have_current_path(event_team_path(event_id: event_teams.id, id: team.id))
      end

      scenario 'user can go to an edit page for a team' do
        visit event_teams_path(event_id: event_teams.id)

        click_on 'Edit the team.'

        expect(page).to have_current_path(edit_event_team_path(event_id: event_teams.id, id: team.id))
      end

      scenario 'user can delete a team', :js do
        visit event_teams_path(event_id: event_teams.id)

        find("div[data-specific-id=\"#{team.id}\"]").click
        click_link(href: "/organise/events/#{event_teams.id}/teams/#{team.id}")

        expect(page).to have_no_content team.name
      end

      scenario 'user can go back to the event page' do
        login_as organiser
        visit event_teams_path(event_id: event_teams.id)

        find_by_id('nav-bar').click_on(event_teams.name)

        expect(page).to have_current_path(event_path(id: event_teams.id))
        expect(page).to have_content event_teams.name
      end
    end

    context 'for a valid event without teams' do
      scenario "user sees the 'no teams' message" do
        visit event_teams_path(event_id: event_no_teams.id)

        expect(page).to have_content 'No teams found for the game'
        expect(page).to have_no_content 'Test team 1'
      end

      scenario 'user can go to a new team page' do
        visit event_teams_path(event_id: event_no_teams.id)

        find_by_id('nav-bar').click_on('New Team')

        expect(page).to have_current_path(new_event_team_path(event_id: event_no_teams.id))
      end

      scenario 'user can go back to the event page' do
        login_as organiser
        visit event_teams_path(event_id: event_no_teams.id)

        find_by_id('nav-bar').click_on(event_no_teams.name)

        expect(page).to have_current_path(event_path(id: event_no_teams.id))
        expect(page).to have_content event_no_teams.name
      end
    end

    context 'for an invalid event' do
      scenario 'user sees the error message' do
        visit event_teams_path(event_id: 99_999_999)
        # expect(page).to have_content 'Event could not be found'
        expect(page).to have_content 'You are not authorised to access this page.'
      end
    end
  end

  context 'as the control team' do
    before do
      OrganiserToEvent.find_by(organiser_id: organiser.id, event_id: event_teams.id)&.update(read_only: true)
      login_as(organiser, scope: :organiser)
    end

    context 'for a valid event with teams' do
      scenario 'user CANNOT go to an edit page for a team' do
        visit event_teams_path(event_id: event_teams.id)

        expect(page).to have_current_path "/organise/events/#{event_teams.id}/teams"
        expect(page).to have_no_link('Edit')
      end

      scenario 'user CANNOT delete a team' do
        visit event_teams_path(event_id: event_teams.id)

        expect(page).to have_current_path "/organise/events/#{event_teams.id}/teams"
        expect(page).to have_no_link('Delete')
      end

      scenario 'user can go back to the event page' do
        login_as organiser
        visit event_teams_path(event_id: event_teams.id)

        find_by_id('nav-bar').click_on(event_teams.name)

        expect(page).to have_current_path(event_path(id: event_teams.id))
        expect(page).to have_content event_teams.name
      end
    end

    context 'for a valid event without teams' do
      scenario "user sees the 'no teams' message" do
        visit event_teams_path(event_id: event_no_teams.id)

        expect(page).to have_content 'No teams found for the game'
        expect(page).to have_no_content 'Test team 1'
      end

      scenario 'user CANNOT go to a new team page' do
        visit event_teams_path(event_id: event_no_teams.id)

        expect(page).to have_current_path "/organise/events/#{event_no_teams.id}/teams"
        expect(page).to have_no_link('New team')
      end

      scenario 'user can go back to the event page' do
        login_as organiser
        visit event_teams_path(event_id: event_no_teams.id)

        find_by_id('nav-bar').click_on(event_no_teams.name)

        expect(page).to have_current_path(event_path(id: event_no_teams.id))
        expect(page).to have_content event_no_teams.name
      end
    end
  end
end
