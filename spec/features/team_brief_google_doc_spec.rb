# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Setting a team brief from a published Google Doc' do
  let(:pub_url) { 'https://docs.google.com/document/d/e/2PACX-abc123/pub' }
  let(:fetched_html) do
    '<html><head><script>window.x=1</script></head>' \
      '<body><div id="contents"><div class="doc-content">Brief body</div></div></body></html>'
  end
  let(:pdf_bytes) { Rails.root.join('spec/fixtures/files/pdf.pdf').binread }

  before do
    @organiser = create(:organiser)
    @event = create(:event)
    @team = create(:team, name: 'Team one', event: @event)
    create(:organiser_to_event, organiser: @organiser, event: @event, read_only: false)
    login_as(@organiser, scope: :organiser)
  end

  # Stub the HTTP fetch and the Grover (Chromium) render so the test stays
  # offline and browser-free while exercising the full request path.
  def stub_google_doc_render
    allow(URI).to receive(:parse).and_call_original
    allow(URI).to receive(:parse).with(pub_url)
                                 .and_return(instance_double(URI::HTTPS, open: StringIO.new(fetched_html)))
    allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: pdf_bytes))
  end

  scenario 'organiser generates a brief PDF from a published Google Doc link' do
    stub_google_doc_render

    visit edit_event_team_path(event_id: @event.id, id: @team.id)
    fill_in 'team_brief_url', with: pub_url
    click_on 'commit'

    expect(page).to have_current_path event_team_path(event_id: @event.id, id: @team.id)
    expect(page).to have_text 'Download brief'
    expect(page).to have_css '#brief-preview'

    @team.reload
    expect(@team.brief).to be_attached
    expect(@team.brief.content_type).to eq('application/pdf')
  end

  scenario 'organiser sees a validation error for a link that is not a published Google Doc' do
    visit edit_event_team_path(event_id: @event.id, id: @team.id)
    fill_in 'team_brief_url', with: 'https://evil.example.com/doc'
    click_on 'commit'

    expect(page).to have_text 'must be a published Google Doc link'
    expect(@team.reload.brief).not_to be_attached
  end
end
