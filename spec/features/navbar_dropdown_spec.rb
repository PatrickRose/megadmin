# frozen_string_literal: true

require 'rails_helper'

# Exercises Bootstrap's Dropdown JS (the account menu in the navbar). The toggle
# is an `href="#"` link, so clicking it only opens the menu -- adding the `.show`
# class and flipping aria-expanded -- when the bundled/transpiled Bootstrap JS is
# actually running. Asserting on `.show` (a JS-set class) rather than on the
# CSS-driven visibility of the items keeps this deterministic.
RSpec.describe 'Navbar account dropdown' do
  let!(:organiser) { create(:organiser) }

  specify 'opens the account menu when the toggle is clicked', :js do
    login_as organiser

    visit events_path

    toggle = find('a.dropdown-toggle', text: organiser.email)
    expect(toggle['aria-expanded']).to eq('false')
    expect(page).to have_no_css('.dropdown-menu.show')

    toggle.click

    expect(page).to have_css('.dropdown-menu.show')
    expect(toggle['aria-expanded']).to eq('true')
    expect(page).to have_link('Log out')
    expect(page).to have_link('Account Settings')
  end
end
