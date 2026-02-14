# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Role edit page' do
  # Setup
  before do
    @organiser = create(:organiser)
    @event = create(:event)

    @team = create(:team, event: @event)
    @new_team = create(:team, name: 'New team', event: @event)

    @role_brief = create(:role, name: 'Role brief', event: @event, team: @team)
    @role_brief.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                             filename: 'pdf.pdf', content_type: 'application/pdf')
    @role_brief.save

    @role_no_brief = create(:role, name: 'Role no brief', event: @event, team: @team)

    @role_unique = create(:role, name: 'ABCD', event: @event, team: @team)
  end

  after do
    Role.delete_all
    Team.delete_all
    Organiser.delete_all
    Event.delete_all
  end

  # Tests
  context 'as an organiser' do
    before do
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: false)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a role with brief attached' do
      scenario 'user can see the page with all the inputs' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        expect(page).to have_content 'Name'
        expect(page).to have_content "Editing Role #{@role_brief.name}"
        expect(page).to have_content 'Brief'
        expect(page).to have_content 'Team'
      end

      scenario 'user can edit the role with valid details' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        fill_in 'role_name', with: 'Edited role'
        attach_file('role_brief', Rails.root.join('spec/fixtures/files/pdf.pdf'))
        select 'New team', from: 'role_team_id'
        click_on 'commit'
        expect(page).to have_current_path(event_role_path(event_id: @event.id, id: @role_brief.id))
        expect(page).to have_content 'Role Edited role'
        expect(page).to have_content 'New team'
      end

      scenario 'user cannot edit the role with blank name' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        fill_in 'role_name', with: '    '
        click_on 'commit'
        expect(page).to have_content "Name can't be blank"
      end

      scenario 'user cannot edit the role with a name that is already taken in its team' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        fill_in 'role_name', with: 'ABCD'
        click_on 'commit'
        expect(page).to have_content 'Name must be unique within a team.'
      end

      scenario 'user cannot edit the role with invalid brief filetype' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        fill_in 'role_name', with: 'Edited role'
        attach_file('role_brief', Rails.root.join('spec/fixtures/files/text.txt'))
        click_on 'commit'
        expect(page).to have_content 'Brief has an invalid content type'
      end

      scenario 'user can go to the teams and roles index page' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        click_on 'Manage Teams'

        expect(page).to have_current_path(event_teams_path(event_id: @event.id))
        expect(page).to have_content 'Role brief'
        expect(page).to have_content 'Role no brief'
      end
    end

    context 'for an invalid event' do
      scenario 'user is shown the error message' do
        visit edit_event_role_path(event_id: 9_999_999, id: @role_brief.id)
        expect(page).to have_content 'You are not authorised to access this page'
      end
    end
  end

  context 'as the control team' do
    before do
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: true)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a role with brief attached' do
      scenario 'control cannot edit the role' do
        visit edit_event_role_path(event_id: @event.id, id: @role_brief.id)
        expect(page).to have_content 'You are not authorised to access this page'
      end
    end
  end
end
