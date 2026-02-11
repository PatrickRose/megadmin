# frozen_string_literal: true

# == Schema Information
#
# Table name: organisers
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_organisers_on_email                 (email) UNIQUE
#  index_organisers_on_reset_password_token  (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe Organiser, type: :feature do
  let!(:organiser2) { create(:organiser, email: 'test_organiser2@email.com', password: 'testpw') }

  specify 'I cannot view new event page if I am not logged in' do
    visit new_event_path

    expect(page).to have_content 'You need to log in or sign up before continuing'
  end

  specify 'I can log in' do
    visit new_organiser_session_path

    fill_in 'Email', with: organiser2.email
    fill_in 'Password', with: organiser2.password

    click_button 'Log in'

    expect(page).to have_content 'Logged in successfully'
  end

  specify 'I cannot log in with the wrong password' do
    visit new_organiser_session_path

    fill_in 'Email', with: organiser2.email
    fill_in 'Password', with: 'wrongpass'

    click_button 'Log in'

    expect(page).to have_content 'Invalid email or password'
  end

  specify 'I can sign up' do
    visit new_organiser_registration_path

    # Check new record is created
    expect do
      fill_in 'organiser_email', with: 'test_organiser@email.com'
      fill_in 'organiser_name', with: 'organiser name'
      fill_in 'organiser_password', with: 'testpw'
      fill_in 'organiser_password_confirmation', with: 'testpw'
      click_button 'Sign up'
    end.to change(described_class, :count).by(1)
    expect(page).to have_content 'Welcome! You have signed up successfully'
  end

  specify 'I can delete all my events' do
    Event.create!(id: 1, name: 'Event 1', date: DateTime.new(2026, 0o3, 15, 15, 31, 0o0),
                  location: 'location',
                  created_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536),
                  updated_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536), organiser_id: organiser2.id)

    Event.create!(id: 2, name: 'Event 2', date: DateTime.new(2026, 0o3, 15, 15, 31, 0o0),
                  location: 'location',
                  created_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536),
                  updated_at: DateTime.new(2025, 0o3, 13, 15, 35, 13, 455_536), organiser_id: organiser2.id)

    expect { organiser2.send(:destroy_owned_events) }.to change {
      Event.where(organiser_id: organiser2.id).count
    }.from(2).to(0)
  end
end
