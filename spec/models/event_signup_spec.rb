# frozen_string_literal: true

# == Schema Information
#
# Table name: event_signups
#
#  id         :bigint           not null, primary key
#  email      :string
#  name       :string
#  uuid       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint
#  role_id    :bigint
#  team_id    :bigint
#
# Indexes
#
#  index_event_signups_on_event_id  (event_id)
#  index_event_signups_on_role_id   (role_id)
#  index_event_signups_on_team_id   (team_id)
#
require 'rails_helper'

RSpec.describe EventSignup, type: :feature do
  let!(:organiser) { create(:organiser) }
  let!(:organiser2) { create(:organiser, email: 'test_organiser2@email.com') }
  let!(:control) { create(:organiser, email: 'test_control@email.com') }
  let!(:event) { create(:event, organiser_id: organiser.id) }
  let!(:event2) { create(:event) }
  let!(:team) { create(:team, event: event) }
  let!(:role) { create(:role, event: event, team: team) }
  let!(:role2) { create(:role, event: event, team: team, name: 'role 2') }
  let!(:role3) { create(:role, event: event, team: team, name: 'role 3') }
  let!(:event_signup) { create(:event_signup, role: role2, team: team, event: event) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event)
    create(:organiser_to_event, organiser: organiser2, event: event2)
    create(:organiser_to_event, organiser: control, event: event, read_only: true)
    create(:event_signup, role: role, team: team, event: event2)
    create(:role, event: event, team: team, name: 'role 1')
  end

  describe 'email_not_in_use validation' do
    it 'rejects a duplicate email for the same event' do
      duplicate = build(:event_signup, email: event_signup.email, event: event, name: 'Duplicate')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base].to_s).to include('already in use')
    end
  end

  specify 'I can create a new event signup.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    find_by_id('nav-bar').click_on('New Player')

    fill_in 'Name', with: 'Player two'
    fill_in 'Email', with: 'playertwo@email.com'
    select team.name, from: 'event_signup_team_id'
    select role3.name, from: 'event_signup_role_id'

    click_on 'Create player'

    expect(page).to have_current_path(event_event_signups_path(event_id: event.id))
    expect(page).to have_content 'Player was successfully created.'
  end

  specify 'I cannot create a signup with an invalid team/role combination' do
    login_as organiser

    # Create a second team with its own role
    team2 = create(:team, name: 'Team 2', event: event)
    role_on_team2 = create(:role, event: event, team: team2, name: 'team2 role')

    visit new_event_event_signup_path(event_id: event.id)

    fill_in 'Name', with: 'Player bad combo'
    fill_in 'Email', with: 'badcombo@email.com'
    # Select team but a role from a different team
    select team.name, from: 'event_signup_team_id'
    select role_on_team2.name, from: 'event_signup_role_id'

    click_on 'Create player'

    expect(page).to have_content 'Invalid combination of team and role'
  end

  specify 'I see validation errors when creating a signup with a duplicate email' do
    login_as organiser

    visit new_event_event_signup_path(event_id: event.id)

    fill_in 'Name', with: 'Duplicate email player'
    fill_in 'Email', with: event_signup.email
    select team.name, from: 'event_signup_team_id'
    select role3.name, from: 'event_signup_role_id'

    click_on 'Create player'

    expect(page).to have_content 'already in use'
  end

  specify 'I see validation errors when updating a signup with a duplicate email' do
    login_as organiser
    signup2 = create(:event_signup, event: event, team: team, role: role3,
                                    name: 'Player three', email: 'playerthree@email.com')

    visit edit_event_event_signup_path(event_id: event.id, id: signup2.id)

    fill_in 'Email', with: event_signup.email

    click_on 'Update player'

    expect(page).to have_content 'already in use'
  end

  specify 'I cannot create a new event signup as control team.' do
    login_as control

    visit event_event_signups_path(event_id: event.id)

    expect(page).to have_content 'Players'
    expect(page).to have_no_link(href: "/organise/events/#{event.id}/event_signups/new")
  end

  # specify "I cannot create a new event signup without a name." do
  #   visit event_event_signups_path(event_id: event.id)

  #   click_on "Add player"

  #   click_on "Create player"

  #   expect(page).to have_content "Name can't be blank"
  # end

  specify 'I can edit an event signup.' do
    login_as organiser

    visit edit_event_event_signup_path(event_id: event.id, id: event_signup.id)

    fill_in 'Name', with: 'Player two'

    click_on 'Update player'

    expect(page).to have_content 'Player was successfully updated.'
    expect(page).to have_content 'Player two'
  end

  specify 'I cannot edit an event signup as control team.' do
    login_as control

    visit edit_event_event_signup_path(event_id: event.id, id: event_signup.id)

    expect(page).to have_content 'You are not authorised to access this page.'
  end

  # specify "I cannot remove necessary fields from an event signup while editing it." do
  #   visit edit_event_event_signup_path(event_id: event.id, id: event_signup.id)

  #   fill_in "Name", with: ""

  #   click_on "Update player"

  #   expect(page).to have_content "Name can't be blank"
  # end

  specify 'I can delete an event signup.', :js do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    find("div[data-specific-id=\"#{event_signup.id}\"]").click
    click_link href: "/organise/events/#{event.id}/event_signups/#{event_signup.id}"

    expect(page).to have_content 'Player was successfully deleted.'
  end

  specify 'I cannot delete an event signup as control team.', :js do
    login_as control

    visit event_event_signups_path(event_id: event.id)

    expect(page).to have_content 'Players'

    expect(page).to have_no_link(href: "/organise/events/#{event.id}/event_signups/#{event_signup.id}")
  end

  specify 'I cannot view event signups that I am not an organiser of' do
    login_as organiser2

    visit event_event_signups_path(event_id: event.id)

    expect(page).to have_content 'You are not authorised to access this page'
  end

  specify 'I can download a cast list for an event that I organise' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    click_on('Download cast list')

    expect(response_headers['Content-Type']).to have_content 'application/pdf'
    expect(response_headers['Content-Disposition']).to have_content 'attachment; ' \
                                                                    "filename=\"#{event.formatted_name} Cast List.pdf\""
  end

  specify 'I cannot download a cast list for an event that does not exist' do
    login_as organiser

    id = 999_999_999_999

    visit organiser_cast_list_event_event_signups_path(event_id: id)

    expect(page).to have_content "The provided event (#{id}) does not exist."
  end
end
