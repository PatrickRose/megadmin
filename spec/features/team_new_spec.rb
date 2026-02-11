# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Team new page' do
  # Setup
  let!(:event) { create(:event) }
  let!(:organiser) { create(:organiser) }

  before do
    create(:organiser_to_event, organiser_id: organiser.id, event_id: event.id, read_only: false)
  end

  after do
    OrganiserToEvent.delete_all
  end

  # Tests
  context 'as a organiser' do
    before do
      login_as(organiser, scope: :organiser)
    end

    context 'for a valid event' do
      scenario 'user can access the create team page' do
        visit new_event_team_path(event_id: event.id)
        expect(page).to have_content 'Create a Team'
      end

      scenario 'user can create a new team with valid paramaters' do
        visit new_event_team_path(event_id: event.id)
        fill_in 'team_name', with: 'Test team'
        attach_file('team_image', Rails.root.join('spec/fixtures/files/image.jpg'))
        attach_file('team_brief', Rails.root.join('spec/fixtures/files/pdf.pdf'))
        click_on 'commit'
        expect(page).to have_content 'Test team'
      end

      scenario 'user cannot create a new team with blank name' do
        visit new_event_team_path(event_id: event.id)
        fill_in 'team_name', with: '   '
        click_on 'commit'
        expect(page).to have_content "Name can't be blank"
      end

      scenario 'user cannot create a team with the same name as another in the same event' do
        visit new_event_team_path(event_id: event.id)
        fill_in 'team_name', with: 'Team 1'
        click_on 'commit'

        visit new_event_team_path(event_id: event.id)
        fill_in 'team_name', with: 'Team 1'
        click_on 'commit'
        expect(page).to have_content 'Name has already been taken for this event'
      end

      scenario 'user cannot attach an invalid filetype to the image upload field' do
        visit new_event_team_path(event_id: event.id)
        fill_in 'team_name', with: 'Test team'
        attach_file('team_image', Rails.root.join('spec/fixtures/files/text.txt'))
        click_on 'commit'
        expect(page).to have_content 'The file must be an image'
      end

      scenario 'user cannot attach an invalid filetype to the brief upload field' do
        visit new_event_team_path(event_id: event.id)
        fill_in 'team_name', with: 'Test team'
        attach_file('team_brief', Rails.root.join('spec/fixtures/files/text.txt'))
        click_on 'commit'
        expect(page).to have_content 'Brief has an invalid content type'
      end

      scenario 'user can go back to view all teams' do
        visit new_event_team_path(event_id: event.id)
        find_by_id('nav-bar').click_on('Manage Teams')
        expect(page).to have_current_path(event_teams_path(event_id: event.id))
      end
    end

    context 'for an invalid event' do
      scenario 'user is shown the error message' do
        visit new_event_team_path(event_id: 9_999_999)
        expect(page).to have_content 'You are not authorised to access this page.'
      end
    end
  end

  context 'as the control team' do
    before do
      OrganiserToEvent.find_by(organiser_id: organiser.id, event_id: event.id)&.update(read_only: true)
      login_as(organiser, scope: :organiser)
    end

    context 'for a valid event' do
      scenario 'user CANNOT access the create team page' do
        visit new_event_team_path(event_id: event.id)
        expect(page).to have_content 'You are not authorised to access this page'
      end
    end
  end
end
