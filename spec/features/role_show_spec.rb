# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Role show page' do
  # Setup
  before do
    @organiser = create(:organiser)
    @event = create(:event)
    @team = create(:team, name: 'Test team', event: @event)

    @role_docx = create(:role, name: 'Role docx', event: @event, team: @team)
    @role_docx.brief.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                            filename: 'docx.docx', content_type: 'application/vnd.openxmlformats-' \
                                                                 'officedocument.wordprocessingml.document')
    @role_docx.save

    @role_pdf = create(:role, name: 'Role pdf', event: @event, team: @team)
    @role_pdf.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                           content_type: 'application/pdf')
    @role_pdf.save

    @role_no_brief = create(:role, name: 'Role no brief', event: @event, team: @team)
  end

  # Tests
  context 'as an organiser' do
    before do
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: false)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a role with a pdf brief' do
      scenario 'user can see the role name' do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        expect(page).to have_content 'Role pdf'
      end

      scenario 'user can see the embedded brief' do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        expect(page).to have_content 'Download brief'
        expect(page).to have_css('#brief-preview')
      end

      scenario "user can go to the role's team page" do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        expect(page).to have_content 'Team'
        click_on 'Test team'
        expect(page).to have_current_path(event_team_path(event_id: @event.id, id: @team.id))
      end

      scenario 'user can go to the edit page for the role' do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        click_on 'Edit the role.'

        expect(page).to have_current_path(edit_event_role_path(event_id: @event.id, id: @role_pdf.id))
      end

      scenario 'user can go back to the index page for teams and roles' do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        click_on 'Manage Teams'
        expect(page).to have_current_path(event_teams_path(event_id: @event.id))
      end

      scenario 'user converting .docx to .pdf does not change the file' do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        click_on 'Convert .docx to .pdf'

        expect(page).to have_content('The .docx files have been successfully converted to .pdf.')
        expect(page).to have_css('#brief-preview')
      end
    end

    context 'for a role with a docx brief' do
      scenario 'user can see the brief could not be previewed message' do
        visit event_role_path(event_id: @event.id, id: @role_docx.id)

        expect(page).to have_content('The brief is not a .pdf file and cannot be previewed.')
        expect(page).to have_no_css('#brief-preview')
      end

      scenario 'user can convert the brief to .pdf' do
        visit event_role_path(event_id: @event.id, id: @role_docx.id)
        click_on 'Convert .docx to .pdf'

        expect(page).to have_content('The .docx files have been successfully converted to .pdf.')
        expect(page).to have_css('#brief-preview')
      end
    end

    context 'for a role with no brief' do
      scenario 'user can see the no brief message' do
        visit event_role_path(event_id: @event.id, id: @role_no_brief.id)
        expect(page).to have_content 'No brief uploaded'
        expect(page).to have_no_content 'Download brief'
        expect(page).to have_no_css('#brief-preview')
      end
    end
  end

  context 'as the control team' do
    before do
      @organiser_event = create(:organiser_to_event, organiser: @organiser, event: @event, read_only: true)
      login_as(@organiser, scope: :organiser)
    end

    context 'for a role with a pdf brief' do
      scenario "user can go to the role's team page" do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)
        expect(page).to have_content 'Team'
        click_on 'Test team'
        expect(page).to have_current_path(event_team_path(event_id: @event.id, id: @team.id))
      end

      scenario 'user CANNOT go to the edit page for the role' do
        visit event_role_path(event_id: @event.id, id: @role_pdf.id)

        expect(page).to have_current_path "/organise/events/#{@event.id}/roles/#{@role_pdf.id}"
        expect(page).to have_no_link('Edit this role')
      end
    end
  end
end
