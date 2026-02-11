# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'EventOrganiserCreates' do
  let!(:organiser) { create(:organiser) }
  let!(:control) { create(:organiser, email: 'test_control@email.com') }
  let!(:event) { create(:event) }

  before do
    create(:organiser_to_event, organiser: organiser, event: event)
    create(:organiser_to_event, organiser: control, event: event, read_only: true)
  end

  specify 'I can upload a player csv with create teams and create roles checkboxes.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/valid_all_headers.csv'))
    check('create_new_teams')
    check('create_new_roles')

    click_on('Upload')

    expect(page).to have_content '3 player(s) were uploaded successfully.'
    expect(page).to have_content 'Jeff'
    expect(page).to have_content 'jeff@jeffmail.com'
    expect(page).to have_content 'team 1'
    expect(page).to have_content 'role 1'
  end

  specify 'I can upload a player csv without create teams and create roles checkboxes.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/valid_all_headers.csv'))

    click_on('Upload')

    expect(page).to have_content '3 player(s) were uploaded successfully.'
    expect(page).to have_content 'Jeff'
    expect(page).to have_content 'jeff@jeffmail.com'
    expect(page).to have_content 'No team'
    expect(page).to have_content 'No role'
    expect(page).to have_content 'The following teams and roles were missing from the event, ' \
                                 'and were not created when uploading.'
    expect(page).to have_content 'team 1'
    expect(page).to have_content 'role 1'
    expect(page).to have_content 'role 2'
    expect(page).to have_content 'team 2'
  end

  specify 'I cannot upload a player csv without create teams and with create roles.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/valid_all_headers.csv'))
    check('create_new_roles')

    click_on('Upload')

    expect(page).to have_content 'Unable to upload players. Cannot create roles without also creating teams.'
  end

  specify 'I cannot upload a valid player csv as control team.' do
    login_as control

    visit event_event_signups_path(event_id: event.id)

    expect(page).to have_content('Players')
    expect(page).to have_no_content 'player_csv'
  end

  specify 'I cannot upload nothing as a player csv.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    click_on('Upload')

    expect(page).to have_content 'Unable to upload players. No file / an incorrect file type has been provided.'
  end

  specify 'I cannot upload a player csv with forbidden headers.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/forbidden_headers.csv'))

    click_on('Upload')

    expect(page).to have_content 'The uploaded CSV contains the following forbidden header(s): \'HELLO\''
  end

  specify 'I cannot upload a player csv without all the correct headers.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/some_headers.csv'))

    click_on('Upload')

    expect(page).to have_content 'The uploaded CSV does not contain the following header(s): \'role\', \'team\'.'
  end

  specify 'I cannot upload a player csv with missing fields in rows.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/malformed_rows.csv'))

    click_on('Upload')

    expect(page).to have_content 'Malformed row on line 4, not enough fields (3, should be 4)'
  end

  specify 'I cannot upload a player csv with invalid emails.' do
    login_as organiser

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/invalid_email.csv'))

    click_on('Upload')

    expect(page).to have_content 'Malformed row on line 2, the email \'jeffjeffmail.com\' is invalid'
  end

  specify 'I cannot upload a player csv with players who are playing already fulfilled roles.' do
    login_as organiser

    team = Team.create!(name: 'team 1', event_id: event.id)
    role = Role.create!(name: 'role 1', event_id: event.id, team_id: team.id)
    EventSignup.create!(event_id: event.id, team: team, role: role, name: 'Fred', email: 'fred@fredmail.com')

    visit event_event_signups_path(event_id: event.id)

    attach_file('player_csv', Rails.root.join('spec/support/files/valid_all_headers.csv'))

    click_on('Upload')

    expect(page).to have_content 'The role \'role 1\' is already fulfilled by \'Fred\' on this team.'
  end
end
