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

  specify 'emails cannot be sent if not all signups have roles' do
    visit event_event_signups_path(event_id: @event.id)

    expect(page).to have_content 'signup 1'
    expect(page).to have_content 'email1@email.com'

    expect(page).to have_content 'signup 2'
    expect(page).to have_content 'email2@email.com'

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(page).to have_content 'a signup is missing a role'
  end

  specify 'emails cannot be sent if not all roles and teams have briefs' do
    @signup1.role = @role1
    @signup2.role = @role2
    @signup1.save
    @signup2.save

    visit event_event_signups_path(event_id: @event.id)

    expect(page).to have_content 'signup 1'
    expect(page).to have_content 'email1@email.com'
    expect(page).to have_content 'role 1'
    expect(page).to have_content 'signup 2'
    expect(page).to have_content 'email2@email.com'
    expect(page).to have_content 'role 2'

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(page).to have_content(/is missing a team or role|are missing teams or roles/)
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

    expect(page).to have_content 'signup 1'
    expect(page).to have_content 'email1@email.com'
    expect(page).to have_content 'role 1'
    expect(page).to have_content 'signup 2'
    expect(page).to have_content 'email2@email.com'
    expect(page).to have_content 'role 2'

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(ActionMailer::Base.deliveries.first.To.value).to eq(@signup1.email)
    expect(ActionMailer::Base.deliveries.first.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.first.Subject.value).to eq('My Event - Pennine Megagames. Event information!')

    expect(ActionMailer::Base.deliveries.second.To.value).to eq(@signup2.email)
    expect(ActionMailer::Base.deliveries.second.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.second.Subject.value).to eq('My Event - Pennine Megagames. Event information!')

    expect(page).to have_content 'Emails sent'
  end

  specify 'emails cannot be sent to individual signups if they dont have a role assigned' do
    visit edit_event_event_signup_path(event_id: @event.id, id: @signup1.id)

    click_button('open-popup')
    Capybara.ignore_hidden_elements = false
    click_button('send-button')

    expect(page).to have_current_path("/organise/events/#{@event.id}/event_signups/#{@signup1.id}/edit")
    expect(page).to have_content "this signup doesn't have a role assigned"
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

    expect(page).to have_content 'Email sent'
  end

  specify 'I cannot send individual emails for draft events' do
    visit edit_event_event_signup_path(event_id: @draft.id, id: @signup2.id)

    expect(page).to have_content 'The event must be published before you can send email briefs to players'
    expect(page).to have_no_button 'button#open-popup'
  end

  specify 'I cannot send all signup emails for draft events' do
    visit event_event_signups_path(event_id: @draft.id)

    expect(page).to have_content 'The event must be published before you can send email briefs to players'
    expect(page).to have_no_button 'button#open-popup'
  end

end
