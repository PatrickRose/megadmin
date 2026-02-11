# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrganiserToEvent do
  let!(:organiser) { create(:organiser, email: 'organiser1@email.com') }
  let!(:control_team) { create(:organiser, email: 'organiser2@email.com') }
  let!(:event) { create(:event, organiser_id: organiser.id) }

  before do
    create(:event, organiser_id: organiser.id, name: 'event 2')
    create(:organiser_to_event, organiser_id: control_team.id, event_id: event.id, read_only: true)
  end

  specify 'I can view players signed up to an event' do
    login_as control_team

    visit events_path

    expect(page).to have_content('My Event')

    click_link(href: "/organise/events/#{event.id}")
  end

  specify 'I can see events Im on control team for' do
    login_as control_team

    visit events_path

    expect(page).to have_content('My Event')
  end

  specify 'I cannot see events Im not on control team for' do
    login_as control_team

    visit events_path

    expect(page).to have_content 'My Events'
    expect(page).to have_no_content 'event 2'
  end
end
