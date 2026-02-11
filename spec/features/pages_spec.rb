# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pages' do
  let!(:organiser) { create(:organiser) }

  # Tests
  context 'user just opened the website' do
    before do
      visit root_path
    end

    scenario 'user stays on the main page' do
      expect(page).to have_content 'Welcome to Megagames!'
      expect(page).to have_link('Sign up')
      expect(page).to have_link('Log in')
      expect(page).to have_link('Legal')
      expect(page).to have_link('Accessibility')
    end

    scenario 'user clicks on the legal page button' do
      click_on 'Legal'
      expect(page).to have_content 'Legal statement'
      expect(page).to have_link('MEGAGAMES')
    end

    scenario 'user clicks on the accessibility page button' do
      click_on 'Accessibility'
      expect(page).to have_content 'Accessibility statement'
      expect(page).to have_link('MEGAGAMES')
    end

    scenario 'user logs in' do
      login_as organiser
      visit root_path

      expect(page).to have_content 'Welcome to Megagames!'
      expect(page).to have_content('Manage events')
      expect(page).to have_no_content('Sign up')
      expect(page).to have_no_content('Log in')
    end
  end

  context 'user returns to the main page' do
    scenario 'from the Legal page' do
      visit legal_path
      click_on 'MEGAGAMES'
      expect(page).to have_content 'Welcome to Megagames!'
      expect(page).to have_link('Sign up')
      expect(page).to have_link('Log in')
    end

    scenario 'from the Accessibility page' do
      visit accessibility_path
      click_on 'MEGAGAMES'
      expect(page).to have_content 'Welcome to Megagames!'
      expect(page).to have_link('Sign up')
      expect(page).to have_link('Log in')
    end
  end
end
