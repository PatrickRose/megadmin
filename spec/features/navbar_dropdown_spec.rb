# frozen_string_literal: true

require 'rails_helper'

# Exercises Bootstrap's Dropdown JS (the account menu in the navbar). Without
# the bundled/transpiled Bootstrap JS running, the menu items stay hidden.
RSpec.describe 'Navbar account dropdown' do
  let!(:organiser) { create(:organiser) }

  specify 'reveals the account actions only after the dropdown is toggled', :js do
    login_as organiser

    visit events_path

    # The toggle (the organiser's email) is always shown; the menu items are
    # hidden until Bootstrap's Dropdown JS reveals them.
    expect(page).to have_link(organiser.email)
    expect(page).to have_no_link('Log out')
    expect(page).to have_no_link('Account Settings')

    find('a.dropdown-toggle', text: organiser.email).click

    expect(page).to have_link('Log out')
    expect(page).to have_link('Account Settings')
  end
end
