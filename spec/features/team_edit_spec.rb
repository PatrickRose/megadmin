# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Team edit page' do
  # Setup
  before do
    @organiser = create(:organiser)
    @event = create(:event)

    @team_both = create(:team, name: 'Team both', event: @event)
    @team_both.image.attach(io: Rails.root.join('spec/fixtures/files/image.jpg').open,
                            filename: 'image.jpg', content_type: 'image/jpeg')
    @team_both.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                            filename: 'pdf.pdf', content_type: 'application/pdf')
    @team_both.save

    @team_neither = create(:team, name: 'Team neither', event: @event)
  end

  # Tests
  context 'as an organiser' do
    before do
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: false)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a team with both image and brief attached' do
      scenario 'user can see the page with all the inputs' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        expect(page).to have_content "Editing Team #{@team_both.name}"
        expect(page).to have_content 'Name'
        expect(page).to have_content 'Icon'
        expect(page).to have_content 'Brief'
      end

      scenario 'user can edit the team with valid details' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        fill_in 'team_name', with: 'Edited team'
        attach_file('team_image', Rails.root.join('spec/fixtures/files/image.jpg'))
        attach_file('team_brief', Rails.root.join('spec/fixtures/files/pdf.pdf'))
        click_on 'commit'
        expect(page).to have_current_path event_team_path(event_id: @event.id, id: @team_both.id)
        expect(page).to have_content 'Team Edited team'
        expect(page).to have_content 'Download icon'
        expect(page).to have_content 'Download brief'
        expect(page).to have_css '#icon-preview'
        expect(page).to have_css '#brief-preview'
      end

      scenario 'user cannot edit the team with blank name' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        fill_in 'team_name', with: '    '
        click_on 'commit'
        expect(page).to have_content "Name can't be blank"
      end

      scenario 'user cannot edit the team with invalid image filetype' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        fill_in 'team_name', with: 'Edited team'
        attach_file('team_image', Rails.root.join('spec/fixtures/files/text.txt'))
        click_on 'commit'
        expect(page).to have_content 'The file must be an image'
      end

      scenario 'user cannot edit the team with invalid brief filetype' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        fill_in 'team_name', with: 'Edited team'
        attach_file('team_brief', Rails.root.join('spec/fixtures/files/text.txt'))
        click_on 'commit'
        expect(page).to have_content 'Brief has an invalid content type'
      end

      scenario 'user can go to the team index page' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        click_on 'Manage Teams'
        expect(page).to have_current_path(event_teams_path(event_id: @event.id))
        expect(page).to have_content 'Team both'
      end
    end
  end

  context 'as the control team' do
    before do
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: true)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a team with both image and brief attached' do
      scenario 'control cannot edit the team' do
        visit edit_event_team_path(event_id: @event.id, id: @team_both.id)
        expect(page).to have_content 'You are not authorised to access this page'
      end
    end
  end
end
