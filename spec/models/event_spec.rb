# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id               :bigint           not null, primary key
#  additional_info  :text
#  date             :datetime
#  description      :text
#  draft            :boolean
#  google_maps_link :string
#  location         :string
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organiser_id     :bigint
#
# Indexes
#
#  index_events_on_organiser_id  (organiser_id)
#
# Foreign Keys
#
#  fk_rails_...  (organiser_id => organisers.id)
#
require 'rails_helper'

RSpec.describe Event, type: :feature do
  before do
    create(:organiser_to_event, organiser: organiser, event: event)
    create(:organiser_to_event, organiser: organiser2, event: event2)
    create(:organiser_to_event, organiser: organiser, event: draft)
    create(:organiser_to_event, organiser: control, event: event, read_only: true)
  end

  after do
    OrganiserToEvent.delete_all
  end

  let!(:organiser) { create(:organiser) }
  let!(:organiser2) { create(:organiser, email: 'test_organiser2@email.com') }
  let!(:control) { create(:organiser, email: 'test_control@email.com') }
  let!(:event) { create(:event, organiser_id: organiser.id) }
  let!(:event2) { create(:event) }
  let!(:draft) { create(:event, draft: true) }

  specify 'I can view a list of my events' do
    login_as organiser

    visit events_path

    expect(page).to have_content('My Event')
  end

  specify 'I can delete an event', :js do
    login_as organiser

    visit events_path

    find('div[title="Delete Event"]').click
    find('a[id="delete-button"]').click

    expect(page).to have_content('Event was successfully deleted.')
  end

  specify 'I can create a new event with minimum details' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'

    # fill_in_trix_editor('event_description', with: 'event desc')

    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Event was successfully created.'
  end

  specify 'I cannot create a new event without the minimum details' do
    login_as organiser

    visit new_event_path

    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')
    fill_in 'event_location', with: 'The location'

    click_on 'Create Event'

    expect(page).to have_content "Name can't be blank"
  end

  specify 'I can create a new event with .pdf rulebook attached' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')

    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/pdf.pdf'))
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Event was successfully created.'
  end

  specify 'I can create a new event with .docx rulebook attached' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/docx.docx'))
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Event was successfully created.'
  end

  specify 'I can create a new event with .doc rulebook attached' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/doc.doc'))
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Event was successfully created.'
  end

  specify 'I cannot create a new event with .txt rulebook attached' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/text.txt'))
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Rulebook has an invalid content type'
  end

  specify 'I can create a new event with .pdf, .doc, and .docx additional documents attached' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')
    attach_file('event_additional_documents', [Rails.root.join('spec/fixtures/files/pdf.pdf'),
                                               Rails.root.join('spec/fixtures/files/docx.docx'),
                                               Rails.root.join('spec/fixtures/files/doc.doc')])
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Event was successfully created.'
  end

  specify 'I cannot create a new event with invalid additional documents filetypes attached' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    # find(:xpath, "//*[@id=\"event_description\"]", visible: false).set('event desc')
    attach_file('event_additional_documents', [Rails.root.join('spec/fixtures/files/pdf.pdf'),
                                               Rails.root.join('spec/fixtures/files/text.txt'),
                                               Rails.root.join('spec/fixtures/files/image.jpg')])
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Create Event'

    expect(page).to have_content 'Additional documents has an invalid content type'
    expect(page).to have_no_content 'Event was successfully created.'
  end

  specify 'I can create a new event as a draft' do
    login_as organiser

    visit new_event_path

    fill_in 'event_name', with: 'The Event'
    fill_in 'event_location', with: 'The location'
    fill_in 'Date and Time:', with: DateTime.now

    click_on 'Save as Draft'

    expect(page).to have_content 'Event was successfully saved as draft.'
  end

  specify 'I can publish a draft', :js do
    login_as organiser

    visit event_path(id: draft.id)

    click_on 'Publish Event'
    click_on 'Publish'

    expect(page).to have_content 'Event was successfully published.'
  end

  specify 'I can edit an event' do
    login_as organiser

    visit edit_event_path(id: event.id)

    fill_in 'event_name', with: 'My updated event'

    click_on 'Update Event'

    expect(page).to have_content 'Event was successfully updated.'
    expect(page).to have_content 'My updated event'
  end

  specify 'I can upload a valid google maps iframe' do
    login_as organiser

    visit edit_event_path(id: event.id)

    fill_in 'event_google_maps_link',
            with: '<iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2379.8492081678423!2d-1.' \
                  '4845092235996877!3d53.381747472074444!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x4879788' \
                  '1e28b3e81%3A0x611c9522ca2169ed!2sThe%20Diamond!5e0!3m2!1sen!2suk!4v1747938036611!5m2!1sen!2suk" ' \
                  'width="600" height="450" style="border:0;" allowfullscreen="" loading="lazy" ' \
                  'referrerpolicy="no-referrer-when-downgrade"></iframe>'

    click_on 'Update Event'

    expect(page).to have_content 'Event was successfully updated.'
  end

  specify 'I can not upload an invalid google maps iframe' do
    login_as organiser

    visit edit_event_path(id: event.id)

    fill_in 'event_google_maps_link', with: '<iframe src="javascript:alert(\'xss\')" width="600" height="450"></iframe>'

    click_on 'Update Event'

    expect(page).to have_content 'Invalid input for Google Maps Iframe.'
  end

  specify 'I can edit an event by attaching a valid rulebook filetype' do
    login_as organiser

    visit edit_event_path(id: event.id)
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/pdf.pdf'))
    click_on 'Update Event'
    expect(page).to have_content 'Event was successfully updated.'

    visit edit_event_path(id: event.id)
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/docx.docx'))
    click_on 'Update Event'
    expect(page).to have_content 'Event was successfully updated.'

    visit edit_event_path(id: event.id)
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/doc.doc'))
    click_on 'Update Event'
    expect(page).to have_content 'Event was successfully updated.'
  end

  specify 'I cannot edit an event by attaching an invalid rulebook filetype' do
    login_as organiser

    visit edit_event_path(id: event.id)
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/text.txt'))
    click_on 'Update Event'
    expect(page).to have_content 'Rulebook has an invalid content type'

    visit edit_event_path(id: event.id)
    attach_file('event_rulebook', Rails.root.join('spec/fixtures/files/image.jpg'))
    click_on 'Update Event'
    expect(page).to have_content 'Rulebook has an invalid content type'
  end

  specify 'I can edit an event by attaching valid additional documents filetypes' do
    login_as organiser

    visit edit_event_path(id: event.id)
    attach_file('event_additional_documents', [Rails.root.join('spec/fixtures/files/pdf.pdf'),
                                               Rails.root.join('spec/fixtures/files/docx.docx'),
                                               Rails.root.join('spec/fixtures/files/doc.doc')])
    click_on 'Update Event'

    expect(page).to have_content 'Event was successfully updated.'
  end

  specify 'I cannot edit an event by attaching invalid additional documents filetypes' do
    login_as organiser

    visit edit_event_path(id: event.id)
    attach_file('event_additional_documents', [Rails.root.join('spec/fixtures/files/pdf.pdf'),
                                               Rails.root.join('spec/fixtures/files/text.txt'),
                                               Rails.root.join('spec/fixtures/files/image.png')])
    click_on 'Update Event'

    expect(page).to have_content 'Additional documents has an invalid content type'
    expect(page).to have_no_content 'Event was successfully updated.'
  end

  specify 'I cannot edit an event without the minimum details' do
    login_as organiser

    visit edit_event_path(id: event.id)

    fill_in 'event_name', with: ''

    click_on 'Update Event'

    expect(page).to have_content "Name can't be blank"
  end

  specify 'I cannot edit an event as a control team' do
    login_as control

    visit edit_event_path(id: event.id)

    expect(page).to have_content 'You are not authorised to access this page'
  end

  specify 'I can see the no brief message in an event with no brief attached' do
    login_as organiser
    visit event_path(id: event.id)

    expect(page).to have_content 'There is no rulebook.'
    expect(page).to have_no_content 'Download rulebook'
    expect(page).to have_no_css('#rulebook-preview')
  end

  specify 'I can view a brief in an event with brief attached' do
    # Setup
    event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                          content_type: 'application/pdf')
    event.save

    # Test
    login_as organiser
    visit event_path(id: event.id)

    expect(page).to have_content 'Download rulebook'
    expect(page).to have_css('#rulebook-preview')
    expect(page).to have_no_content 'There is no rulebook.'
  end

  specify 'I can see the rulebook could not be previewed message in an event with a doc rulebook' do
    # Setup
    event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/doc.doc').open, filename: 'doc.doc',
                          content_type: 'application/msword')
    event.save

    # Test
    login_as organiser
    visit event_path(id: event.id)

    expect(page).to have_content 'The rulebook is not a .pdf file and cannot be previewed.'
    expect(page).to have_no_css('#rulebook-preview')
    expect(page).to have_no_content 'There is no rulebook.'
  end

  specify 'I can see the no additional documents message in an event without them attached' do
    login_as organiser
    visit event_path(id: event.id)

    expect(page).to have_content 'There are no additional documents.'
    expect(page).to have_no_css('#doc-preview')
  end

  specify 'I can view additional documents in an event with them attached' do
    # Setup
    event.additional_documents.attach([{ io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                                         content_type: 'application/pdf' },
                                       { io: Rails.root.join('spec/fixtures/files/doc.doc').open, filename: 'doc.doc',
                                         content_type: 'application/msword' }])
    event.save

    # Test
    login_as organiser
    visit event_path(id: event.id)

    expect(page).to have_content 'pdf.pdf'
    expect(page).to have_content 'doc.doc'
    expect(page).to have_css('#doc-preview')
    expect(page).to have_no_content 'There are no additional documents.'
  end

  specify 'I cannot view an event that I am not an organiser of' do
    login_as organiser2

    visit event_path(id: event.id)

    expect(page).to have_content 'You are not authorised to access this page'
  end

  specify 'I can convert .docx files to .pdf' do
    # Setup
    event.rulebook.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open, filename: 'docx.docx',
                          content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    event.additional_documents.attach([{ io: Rails.root.join('spec/fixtures/files/pdf.pdf').open,
                                         filename: 'pdf.pdf',
                                         content_type: 'application/pdf' },
                                       { io: Rails.root.join('spec/fixtures/files/doc.doc').open,
                                         filename: 'doc.doc',
                                         content_type: 'application/msword' },
                                       { io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                                         filename: 'docx.docx',
                                         content_type: 'application/vnd.openxmlformats-officedocument' \
                                                       '.wordprocessingml.document' }])
    event.save

    # Test
    login_as organiser
    visit event_path(id: event.id)
    click_on 'Convert .docx to .pdf'

    expect(page).to have_content('The .docx files have been successfully converted to .pdf.')
    expect(page).to have_no_content('The rulebook is not a .pdf file and cannot be previewed.')
    expect(page).to have_content('pdf.pdf')
    expect(page).to have_content('doc.doc')
    expect(page).to have_content('docx.pdf')
  end
end
