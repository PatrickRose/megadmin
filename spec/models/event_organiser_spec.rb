# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrganiserToEvent do
  let!(:organiser) { create(:organiser, email: 'organiser1@email.com') }
  let!(:organiser2) { create(:organiser, email: 'organiser3@email.com') }
  let!(:control_team) { create(:organiser, email: 'organiser2@email.com') }
  let!(:event) { create(:event, organiser_id: organiser.id) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event)
    create(:organiser_to_event, organiser: organiser2, event: event)
  end

  specify 'I can add an organiser to an event' do
    login_as organiser

    visit event_event_organisers_path(event_id: event.id)

    expect(page).to have_current_path("/organise/events/#{event.id}/event_organisers")
    expect(page).to have_content 'organiser1@email.com'

    find_by_id('nav-bar').click_on('Add Organisers')

    expect(page).to have_current_path("/organise/events/#{event.id}/event_organisers/new")

    fill_in 'email', with: control_team.email
    fill_in 'description', with: 'control team role description'

    check 'read_only'

    click_on 'Add Organiser'

    expect(page).to have_current_path("/organise/events/#{event.id}/event_organisers")
    expect(page).to have_content 'Organiser added to event'
    expect(page).to have_content organiser.email
    expect(page).to have_content control_team.email
    expect(page).to have_content 'Control team'
    expect(page).to have_content 'control team role description'
  end

  specify 'I can remove an organiser from an event', :js do
    login_as organiser
    event.organiser_id = organiser.id
    event.organisers << organiser

    organiser.save
    control_team.save

    described_class.find_by(organiser_id: organiser.id).read_only = false
    o = described_class.new(event_id: event.id, organiser_id: control_team.id, read_only: true)
    o.save
    id_org2 = described_class.find_by(organiser_id: control_team.id).id

    visit event_event_organisers_path(event_id: event.id)

    find("div[data-specific-id=\"#{id_org2}\"]").click
    click_link(href: "/organise/events/#{event.id}/event_organisers/#{id_org2}")

    expect(page).to have_content 'Organiser successfully removed from event'
    expect(page).to have_content 'organiser1@email.com'
    expect(page).to have_no_content 'organiser2@email.com'
  end

  specify 'I can move an organiser to control team' do
    login_as organiser

    event.organiser_id = organiser.id
    event.organisers << organiser
    organiser.save
    control_team.save

    described_class.find_by(organiser_id: organiser.id).read_only = false
    o = described_class.new(event_id: event.id, organiser_id: control_team.id, read_only: true)
    o.save
    id_org2 = described_class.find_by(organiser_id: control_team.id).id

    visit event_event_organisers_path(event_id: event.id)

    expect(page).to have_current_path("/organise/events/#{event.id}/event_organisers")
    expect(page).to have_content organiser.email
    expect(page).to have_content control_team.email

    click_link(href: "/organise/events/#{event.id}/event_organisers/#{id_org2}/edit")

    expect(page).to have_current_path("/organise/events/#{event.id}/event_organisers/#{id_org2}/edit")

    uncheck 'organiser_to_event_read_only'

    click_on 'Update organiser'

    expect(page).to have_content organiser.email
    expect(page).to have_content control_team.email
    expect(page).to have_content 'Organiser'
    expect(page).to have_no_content 'Control team'
  end

  specify 'I cannot remove the event author from an event', :js do
    login_as organiser

    event.organiser_id = organiser.id
    event.organisers << organiser
    organiser.save
    control_team.save

    described_class.find_by(organiser_id: organiser.id).read_only = false
    o = described_class.new(event_id: event.id, organiser_id: control_team.id, read_only: true)
    o.save

    id = described_class.find_by(organiser_id: organiser.id).id

    visit event_event_organisers_path(event_id: event.id)

    find("div[data-specific-id=\"#{id}\"]").click
    click_link(href: "/organise/events/#{event.id}/event_organisers/#{id}")

    expect(page).to have_content '(You) organiser1@email.com'
    expect(page).to have_content 'Cannot remove event author from event'
  end

  specify 'I cannot remove myself from an event', :js do
    login_as organiser2

    visit event_event_organisers_path(event_id: event.id)
    find("div[data-specific-id=\"#{organiser2.id}\"]").click
    click_link(href: "/organise/events/#{event.id}/event_organisers/#{organiser2.id}")

    expect(page).to have_content "(You) #{organiser2.email}"
    expect(page).to have_content 'Cannot remove yourself from event'
  end
end
