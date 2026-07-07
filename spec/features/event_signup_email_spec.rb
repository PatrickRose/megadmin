# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'EventSignupEmails' do
  before do
    @organiser = create(:organiser)
    @event = create(:event, organiser_id: @organiser.id)
    @draft = create(:event, organiser_id: @organiser.id, draft: true)
    @event.organisers << @organiser
    @draft.organisers << @organiser

    @organiser_to_event = create(:organiser_to_event,
                                 event_id: @event.id,
                                 organiser_id: @organiser.id)

    @organiser_to_draft = create(:organiser_to_event,
                                 event_id: @draft.id,
                                 organiser_id: @organiser.id)

    @team = create(:team, event: @event)

    @role1 = create(:role, event: @event, name: 'role 1', team: @team)
    @role2 = create(:role, event: @event, name: 'role 2', team: @team)

    @signup1 = create(:event_signup, event: @event,
                                     name: 'signup 1',
                                     email: 'email1@email.com', role: nil)
    @signup2 = create(:event_signup, event: @event,
                                     name: 'signup 2',
                                     email: 'email2@email.com', role: nil)
    @signup3 = create(:event_signup, event: @draft,
                                     name: 'signup 3',
                                     email: 'email3@email.com')

    login_as @organiser
  end

  # Several examples flip Capybara.ignore_hidden_elements to reach the hidden
  # popup content; restore it afterwards so the change can't leak into other
  # (randomly ordered) feature specs.
  around do |example|
    original = Capybara.ignore_hidden_elements
    example.run
    Capybara.ignore_hidden_elements = original
  end

  specify 'emails cannot be sent if not all signups have roles' do
    visit event_event_signups_path(event_id: @event.id)

    expect(page).to have_text 'signup 1'
    expect(page).to have_text 'email1@email.com'

    expect(page).to have_text 'signup 2'
    expect(page).to have_text 'email2@email.com'

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(page).to have_text 'a signup is missing a role'
  end

  specify 'the checklist flags players who have not been assigned a role' do
    visit event_event_signups_path(event_id: @event.id)
    Capybara.ignore_hidden_elements = false

    within('.email-checklist') do
      expect(page).to have_text '✗ Some players are missing a team or role'
      # The unassigned players are listed inside the checklist accordion.
      expect(page).to have_text 'signup 1'
      expect(page).to have_text 'signup 2'
    end
  end

  specify 'the checklist reports missing team and role briefs separately' do
    @signup1.update!(role: @role1, team: @team)
    @signup2.update!(role: @role2, team: @team)
    # Give the team a brief but leave the roles without one. The role briefs are
    # still missing, and the checklist must say so without conflating the two.
    @team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                       content_type: 'application/pdf')
    @team.save

    visit event_event_signups_path(event_id: @event.id)
    Capybara.ignore_hidden_elements = false

    within('.email-checklist') do
      # Assignment and team-brief checks pass; only the role-brief check fails.
      expect(page).to have_text '✓ All roles assigned'
      expect(page).to have_text '✓ All teams have briefing files'
      expect(page).to have_text '✗ Some roles are missing briefing files'
      expect(page).to have_text 'role 1'
      expect(page).to have_text 'role 2'
    end
  end

  specify 'the brief checks are hidden when brief validation is turned off for the event' do
    @event.update!(skip_brief_validation: true)
    @signup1.update!(role: @role1, team: @team)
    @signup2.update!(role: @role2, team: @team)

    visit event_event_signups_path(event_id: @event.id)
    Capybara.ignore_hidden_elements = false

    within('.email-checklist') do
      expect(page).to have_text 'All roles assigned'
      expect(page).to have_no_text 'All teams have briefing files'
      expect(page).to have_no_text 'All roles have briefing files'
    end
  end

  specify 'the checklist passes when everything is assigned and briefed' do
    @role1.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                        content_type: 'application/pdf')
    @role2.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                        content_type: 'application/pdf')
    @team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                       content_type: 'application/pdf')
    @role1.save
    @role2.save
    @team.save
    @signup1.update!(role: @role1, team: @team)
    @signup2.update!(role: @role2, team: @team)

    visit event_event_signups_path(event_id: @event.id)
    Capybara.ignore_hidden_elements = false

    within('.email-checklist') do
      expect(page).to have_text '✓ All roles assigned'
      expect(page).to have_text '✓ All teams have briefing files'
      expect(page).to have_text '✓ All roles have briefing files'
      expect(page).to have_no_text '✗'
    end
  end

  specify 'emails can be sent to all signups with roles with briefs' do
    @role1.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                        content_type: 'application/pdf')
    @role2.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                        content_type: 'application/pdf')
    @role1.save
    @role2.save

    @signup1.role = @role1
    @signup2.role = @role2
    @signup1.save
    @signup2.save

    visit event_event_signups_path(event_id: @event.id)

    expect(page).to have_text 'signup 1'
    expect(page).to have_text 'email1@email.com'
    expect(page).to have_text 'role 1'
    expect(page).to have_text 'signup 2'
    expect(page).to have_text 'email2@email.com'
    expect(page).to have_text 'role 2'

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(ActionMailer::Base.deliveries.first.To.value).to eq(@signup1.email)
    expect(ActionMailer::Base.deliveries.first.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.first.Subject.value).to eq('My Event - Pennine Megagames. Event information!')

    expect(ActionMailer::Base.deliveries.second.To.value).to eq(@signup2.email)
    expect(ActionMailer::Base.deliveries.second.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.second.Subject.value).to eq('My Event - Pennine Megagames. Event information!')

    expect(page).to have_text 'Emails sent'
  end

  specify 'emails cannot be sent to individual signups if they dont have a role assigned' do
    visit edit_event_event_signup_path(event_id: @event.id, id: @signup1.id)

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(page).to have_current_path("/organise/events/#{@event.id}/event_signups/#{@signup1.id}/edit")
    expect(page).to have_text "this signup doesn't have a role assigned"
  end

  specify 'emails can be sent to individual signups' do
    @signup1.role = @role1
    @signup1.save

    visit edit_event_event_signup_path(event_id: @event.id, id: @signup1.id)

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(ActionMailer::Base.deliveries.first.To.value).to eq(@signup1.email)
    expect(ActionMailer::Base.deliveries.first.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.first.Subject.value).to eq('My Event - Pennine Megagames. Event information!')

    expect(page).to have_text 'Email sent'
  end

  specify 'the single-player checklist reports missing team and role briefs' do
    @signup1.update!(role: @role1, team: @team)

    visit edit_event_event_signup_path(event_id: @event.id, id: @signup1.id)
    Capybara.ignore_hidden_elements = false

    within('.email-checklist') do
      expect(page).to have_text '✓ This player has a team and role assigned'
      expect(page).to have_text '✗ Their team is missing a briefing file'
      expect(page).to have_text '✗ Their role is missing a briefing file'
    end
  end

  specify 'the single-player brief checks are hidden when brief validation is off' do
    @event.update!(skip_brief_validation: true)
    @signup1.update!(role: @role1, team: @team)

    visit edit_event_event_signup_path(event_id: @event.id, id: @signup1.id)
    Capybara.ignore_hidden_elements = false

    within('.email-checklist') do
      expect(page).to have_text 'This player has a team and role assigned'
      expect(page).to have_no_text 'briefing file'
    end
  end

  specify 'I cannot send individual emails for draft events' do
    visit edit_event_event_signup_path(event_id: @draft.id, id: @signup2.id)

    expect(page).to have_text 'The event must be published before you can send email briefs to players'
    expect(page).to have_no_button 'button#open-popup'
  end

  specify 'I cannot send all signup emails for draft events' do
    visit event_event_signups_path(event_id: @draft.id)

    expect(page).to have_text 'The event must be published before you can send email briefs to players'
    expect(page).to have_no_button 'button#open-popup'
  end
end
