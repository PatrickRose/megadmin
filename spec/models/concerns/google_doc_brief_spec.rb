# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleDocBrief do
  # Team includes the concern; the behaviour is identical for Role.
  subject(:team) { build(:team, event: create(:event)) }

  let(:valid_url) { 'https://docs.google.com/document/d/e/2PACX-abc123/pub' }
  let(:fetched_html) do
    '<html><head><script>window.x=1</script></head>' \
      '<body><div id="contents"><div class="c1 doc-content">Brief body</div></div></body></html>'
  end
  let(:pdf_bytes) { Rails.root.join('spec/fixtures/files/pdf.pdf').binread }

  # Stubs the two external boundaries: the HTTP fetch and the Grover (Chromium)
  # render, so the concern's own logic runs without network or a browser.
  def stub_fetch_and_grover(capture: nil)
    allow(URI).to receive(:parse).and_call_original
    allow(URI).to receive(:parse).with(valid_url)
                                 .and_return(instance_double(URI::HTTPS, open: StringIO.new(fetched_html)))
    allow(Grover).to receive(:new) do |html, **opts|
      capture&.call(html, opts)
      instance_double(Grover, to_pdf: pdf_bytes)
    end
  end

  describe 'brief_url validation' do
    it 'is valid when brief_url is blank' do
      team.brief_url = ''
      expect(team).to be_valid
    end

    it 'is valid with a published Google Doc URL' do
      team.brief_url = valid_url
      expect(team).to be_valid
    end

    it 'is valid with a published Google Doc URL that has query params' do
      team.brief_url = "#{valid_url}?embedded=true"
      expect(team).to be_valid
    end

    it 'is invalid with a non-Google-Doc URL' do
      team.brief_url = 'https://evil.example.com/doc'
      expect(team).not_to be_valid
      expect(team.errors[:brief_url]).to be_present
    end

    it 'is invalid with a Google Docs edit URL that is not published' do
      team.brief_url = 'https://docs.google.com/document/d/abc123/edit'
      expect(team).not_to be_valid
    end

    it 'is included by Role as well' do
      role = build(:role, event: create(:event))
      role.brief_url = 'https://evil.example.com/doc'
      expect(role).not_to be_valid
      expect(role.errors[:brief_url]).to be_present
    end
  end

  describe '#brief_from_google_doc' do
    before { team.save! }

    it 'does nothing when the url is blank' do
      team.brief_from_google_doc('')
      expect(team.brief).not_to be_attached
    end

    it 'raises for a non-Google-Doc url' do
      expect { team.brief_from_google_doc('https://evil.example.com') }
        .to raise_error(ArgumentError)
    end

    it 'fetches, renders and attaches the brief as a pdf' do
      stub_fetch_and_grover
      team.brief_from_google_doc(valid_url)
      expect(team.brief).to be_attached
      expect(team.brief.content_type).to eq('application/pdf')
      expect(team.brief.filename.to_s).to eq('brief.pdf')
    end

    it 'strips whitespace around the url before matching and fetching' do
      stub_fetch_and_grover
      team.brief_from_google_doc("  #{valid_url}  ")
      expect(team.brief).to be_attached
    end

    it 'prepares the html with a utf-8 charset, chrome-hiding css and a clickable source link' do
      captured_html = nil
      stub_fetch_and_grover(capture: ->(html, _opts) { captured_html = html })

      team.brief_from_google_doc(valid_url)

      expect(captured_html).to include('<meta charset="utf-8">')
      expect(captured_html).to include('#banners{display:none')
      expect(captured_html).to include('#contents{padding:0')
      expect(captured_html).to include(%(<a href="#{valid_url}"))
      expect(captured_html).to include('Automatically generated from')
    end

    it 'renders at A4 size' do
      captured_opts = nil
      stub_fetch_and_grover(capture: ->(_html, opts) { captured_opts = opts })

      team.brief_from_google_doc(valid_url)

      expect(captured_opts[:format]).to eq('A4')
    end
  end
end
