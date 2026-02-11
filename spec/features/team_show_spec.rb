# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Team show page' do
  # Setup
  before do
    @event = create(:event)

    @team_image_pdf = create(:team, name: 'team image pdf', event: @event)
    @team_image_pdf.image.attach(io: Rails.root.join('spec/fixtures/files/image.jpg').open,
                                 filename: 'image.jpg', content_type: 'image/jpeg')
    @team_image_pdf.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                 filename: 'pdf.pdf', content_type: 'application/pdf')
    @team_image_pdf.save

    @team_image_docx = create(:team, name: 'team image docx', event: @event)
    @team_image_docx.image.attach(io: Rails.root.join('spec/fixtures/files/image.jpg').open,
                                  filename: 'image.jpg', content_type: 'image/jpeg')
    @team_image_docx.brief.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                                  filename: 'docx.docx',
                                  content_type: 'application/vnd.openxmlformats-officedocument.' \
                                                'wordprocessingml.document')
    @team_image_docx.save

    @team_image = create(:team, name: 'team image', event: @event)
    @team_image.image.attach(io: Rails.root.join('spec/fixtures/files/image.jpg').open,
                             filename: 'image.jpg', content_type: 'image/jpeg')
    @team_image.save

    @team_pdf = create(:team, name: 'team pdf', event: @event)
    @team_pdf.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                           filename: 'pdf.pdf', content_type: 'application/pdf')
    @team_pdf.save

    @team_neither = create(:team, name: 'team neither', event: @event)

    @role = create(:role, name: 'test role', event: @event, team: @team_image_pdf)
  end

  # Logged in as the organiser
  context 'as an organiser' do
    before do
      @organiser = create(:organiser)
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: false)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a team with an image, a pdf brief, and a role' do
      scenario 'user can see the team name' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        expect(page).to have_content 'team image pdf'
      end

      scenario 'user can see the image' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        expect(page).to have_content 'Download icon'
        expect(page).to have_css('#icon-preview')
      end

      scenario 'user can see the embedded brief' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        expect(page).to have_content 'Download brief'
        expect(page).to have_css('#brief-preview')
      end

      scenario 'user can see the list of roles assigned to the team' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        expect(page).to have_content 'Roles'
        expect(page).to have_content 'test role'
        click_on 'test role'
        expect(page).to have_current_path(event_role_path(event_id: @event.id, id: @role.id))
      end

      scenario 'user can go to the edit page for the team' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        click_on 'Edit the team.'
        expect(page).to have_current_path(edit_event_team_path(event_id: @event.id, id: @team_image_pdf.id))
      end

      scenario 'user can go back to the index page for the teams' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        find_by_id('nav-bar').click_on('Manage Teams')
        expect(page).to have_current_path(event_teams_path(event_id: @event.id))
      end

      scenario 'user converting .docx to .pdf does not change the file' do
        visit event_team_path(event_id: @event.id, id: @team_image_pdf.id)
        click_on 'Convert .docx to .pdf'

        expect(page).to have_content('The .docx files have been successfully converted to .pdf.')
        expect(page).to have_css('#brief-preview')
      end
    end

    context 'for a team with an image and a docx brief' do
      scenario 'user can see the image' do
        visit event_team_path(event_id: @event.id, id: @team_image_docx.id)

        expect(page).to have_content 'Download icon'
        expect(page).to have_css('#icon-preview')
      end

      scenario 'user can see the brief could not be previewed message' do
        visit event_team_path(event_id: @event.id, id: @team_image_docx.id)

        expect(page).to have_content('The brief is not a .pdf file and cannot be previewed.')
        expect(page).to have_no_css('#brief-preview')
      end

      scenario 'user can convert the brief to .pdf' do
        visit event_team_path(event_id: @event.id, id: @team_image_docx.id)
        click_on 'Convert .docx to .pdf'

        expect(page).to have_content('The .docx files have been successfully converted to .pdf.')
        expect(page).to have_css('#brief-preview')
      end
    end

    context 'for a team with an image but no brief' do
      scenario 'user can see the image' do
        visit event_team_path(event_id: @event.id, id: @team_image.id)
        expect(page).to have_content 'Download icon'
        expect(page).to have_css('#icon-preview')
      end

      scenario 'user can see the no brief message' do
        visit event_team_path(event_id: @event.id, id: @team_image.id)
        expect(page).to have_content 'No brief uploaded'
        expect(page).to have_no_content 'Download brief'
        expect(page).to have_no_css('#brief-preview')
      end
    end

    context 'for a team with a pdf brief but no image' do
      scenario 'user can see the no image message' do
        visit event_team_path(event_id: @event.id, id: @team_pdf.id)
        expect(page).to have_content 'No icon uploaded'
        expect(page).to have_no_content 'Download icon'
        expect(page).to have_no_css('#icon-preview')
      end

      scenario 'user can see the embedded brief' do
        visit event_team_path(event_id: @event.id, id: @team_pdf.id)
        expect(page).to have_content 'Download brief'
        expect(page).to have_css('#brief-preview')
      end
    end

    context 'for a team with neither an image, a brief, nor a role' do
      scenario 'user can see the no image message' do
        visit event_team_path(event_id: @event.id, id: @team_neither.id)
        expect(page).to have_content 'No icon uploaded'
        expect(page).to have_no_content 'Download icon'
        expect(page).to have_no_css('#icon-preview')
      end

      scenario 'user can see the no roles message' do
        visit event_team_path(event_id: @event.id, id: @team_neither.id)
        expect(page).to have_content 'This team has no roles yet'
        expect(page).to have_no_content 'test role'
      end

      scenario 'user can see the no brief message' do
        visit event_team_path(event_id: @event.id, id: @team_neither.id)
        expect(page).to have_content 'No brief uploaded'
        expect(page).to have_no_content 'Download brief'
        expect(page).to have_no_css('#brief-preview')
      end
    end
  end

  # Logged in as a control team member
  context 'as the control team' do
    before do
      @organiser = create(:organiser)
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: true)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a team' do
      scenario 'user CANNOT access the create team page' do
        visit new_event_team_path(event_id: @event.id)
        expect(page).to have_content 'You are not authorised to access this page'
      end
    end
  end
end
