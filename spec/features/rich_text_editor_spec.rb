# frozen_string_literal: true

require 'rails_helper'

# Exercises the Trix rich-text editor (via ActionText's rich_text_area on the
# event form). Trix's JS upgrades the <trix-editor> element and renders its
# toolbar; without the transpiled bundle it would stay an inert element and
# nothing would be captured on submit.
RSpec.describe 'Rich text (Trix) editor' do
  let!(:organiser) { create(:organiser) }

  specify 'boots the editor and persists what the user types', :js do
    login_as organiser

    visit new_event_path

    # Trix has initialised: the custom element and its toolbar are rendered.
    expect(page).to have_css('trix-editor')
    expect(page).to have_css('trix-toolbar')

    fill_in 'event_name', with: 'A JS-tested event'
    fill_in 'event_location', with: 'Somewhere'
    fill_in 'Date and Time:', with: DateTime.now

    # The Trix editor is a contenteditable element, so type into it directly.
    first('trix-editor').click.send_keys('Rich text typed via Trix')

    click_on 'Save as Draft'

    expect(page).to have_text 'Event was successfully saved as draft.'
    expect(Event.last.description.to_plain_text).to include('Rich text typed via Trix')
  end
end
