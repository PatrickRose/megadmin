# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'EventOrganiserCreates' do
  before do
    @organiser1 = create(:organiser, email: 'email1@email.com')
    @organiser2 = create(:organiser, email: 'email2@email.com')

    @event = create(:event, organiser_id: @organiser1.id)

    @organiser_to_event = create(:organiser_to_event,
                                 event_id: @event.id,
                                 organiser_id: @organiser1.id)

    login_as @organiser1
  end

  specify 'cannot view add organiser page if not an event organiser' do
    login_as @organiser2

    visit event_event_organisers_path(event_id: @event.id)

    expect(page).to have_content 'You are not authorised to access this page.'
  end

  specify 'organisers without accounts get emailed to setup an account' do
    visit event_event_organisers_path(event_id: @event.id)

    expect(page).to have_content 'email1@email.com'
    expect(page).to have_no_content 'email2@email.com'

    click_link(href: "/organise/events/#{@event.id}/event_organisers/new")

    fill_in 'email', with: 'email3@email.com'

    click_on 'Add Organiser'

    expect(page).to have_content 'email3@email.com'

    expect(ActionMailer::Base.deliveries.first.To.value).to eq 'email3@email.com'
    expect(ActionMailer::Base.deliveries.first.From.value).to eq 'no-reply@megadmin.patrickrosemusic.co.uk'
    expect(ActionMailer::Base.deliveries.first.Subject.value).to eq 'An account has been created for you for ' \
                                                                    'Pennine Megagames!'
    expect(ActionMailer::Base.deliveries.first.To.value).to eq 'email3@email.com'
  end

  specify 'organisers already assigned to an event cannot be added again' do
    visit event_event_organisers_path(event_id: @event.id)

    expect(page).to have_content 'email1@email.com'
    expect(page).to have_no_content 'email2@email.com'

    click_link(href: "/organise/events/#{@event.id}/event_organisers/new")

    fill_in 'email', with: 'email2@email.com'

    click_on 'Add Organiser'

    expect(page).to have_current_path("/organise/events/#{@event.id}/event_organisers")

    click_link(href: "/organise/events/#{@event.id}/event_organisers/new")

    fill_in 'email', with: 'email2@email.com'

    click_on 'Add Organiser'

    expect(page).to have_content 'Organiser already assigned'
  end
end
