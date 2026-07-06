# frozen_string_literal: true

require 'open-uri'

# Lets a model's `brief` attachment be populated from a published Google Doc.
#
# The organiser pastes a "Publish to the web" link
# (https://docs.google.com/document/d/e/<key>/pub); we render it to a PDF with
# Grover (headless Chromium) and store the result as the normal `brief`
# attachment, so every downstream feature (preview, download, zip, email)
# keeps working unchanged.
module GoogleDocBrief
  extend ActiveSupport::Concern

  # Published Google Doc URL, e.g. https://docs.google.com/document/d/e/<key>/pub
  # (an optional query string such as ?embedded=true is allowed).
  GOOGLE_DOC_PUB_URL = %r{\Ahttps://docs\.google\.com/document/d/e/[\w-]+/pub}

  # Hides Google's publish chrome (banner, header/footer) and removes the
  # centred 20% padding so the content fills the page. Targets only stable
  # selectors, not the per-publish random class names.
  CLEANUP_CSS = <<~CSS
    #banners{display:none !important;}
    #header,#footer{display:none !important;}
    #contents{padding:0 !important;}
    .doc-content{max-width:none !important; margin:0 !important;}
  CSS

  included do
    # Virtual attribute so the URL can flow through the form and mass-assignment
    # without being a database column.
    attr_accessor :brief_url

    validate :validate_brief_url_format
  end

  # Fetches the published doc, renders it to PDF and attaches it as `brief`.
  # Raises on a non-Google-Doc URL or any fetch/render failure.
  def brief_from_google_doc(url)
    url = url.to_s.strip
    return if url.blank?
    raise ArgumentError, 'That is not a published Google Doc link.' unless url.match?(GOOGLE_DOC_PUB_URL)

    pdf = Grover.new(brief_html_from_google_doc(url), format: 'A4', wait_until: 'networkidle0',
                                                      margin: { top: '0.6in', bottom: '0.6in',
                                                                left: '0.6in', right: '0.6in' }).to_pdf

    brief.attach(io: StringIO.new(pdf), filename: 'brief.pdf', content_type: 'application/pdf')
  end

  private

  # Downloads the published HTML and prepares it for Grover: forces UTF-8 (the
  # doc's charset meta is pushed past Chromium's sniff window by a large inline
  # script), injects the cleanup CSS, and appends a clickable source link.
  def brief_html_from_google_doc(url)
    html = URI.parse(url).open.read
    safe_url = CGI.escapeHTML(url)
    link = <<~HTML
      <p style="margin-top:28px;font-size:9pt;color:#666;font-family:Roboto,arial,sans-serif;">
      Automatically generated from <a href="#{safe_url}" style="color:#1155cc;">#{safe_url}</a></p>
    HTML

    html = with_charset_meta(html)
    html = html.sub(%r{</head>}i, "<style>#{CLEANUP_CSS}</style></head>")
    html.sub(%r{</body>}i, "#{link}</body>")
  end

  # Inserts a UTF-8 charset meta as the first thing inside <head>. Uses plain
  # linear string searches rather than a backtracking regex, so it can't be a
  # ReDoS vector on the fetched (untrusted) HTML.
  def with_charset_meta(html)
    meta = '<meta charset="utf-8">'
    open_head = (html =~ /<head[\s>]/i)
    return "#{meta}#{html}" if open_head.nil?

    close = html.index('>', open_head)
    return html if close.nil?

    html.dup.insert(close + 1, meta)
  end

  def validate_brief_url_format
    return if brief_url.blank?
    return if brief_url.to_s.strip.match?(GOOGLE_DOC_PUB_URL)

    errors.add(:brief_url, 'must be a published Google Doc link (…/document/d/e/…/pub)')
  end
end
