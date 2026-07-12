# frozen_string_literal: true

require 'rails_helper'
require 'pdf/reader'
require 'stringio'

RSpec.describe OrganiserCastListPdf do
  def pdf_text(bytes)
    PDF::Reader.new(StringIO.new(bytes)).pages.flat_map { |page| page.text.split("\n") }.join("\n")
  end

  let(:owner) { create(:organiser, name: 'Olivia Owner', email: 'owner@example.com') }
  let(:event) { create(:event, name: 'Winter Clash', organiser_id: owner.id) }

  it 'renders a valid PDF document' do
    expect(described_class.new(event).render).to start_with('%PDF')
  end

  it 'adds a Present attendance column alongside the player and role' do
    team = create(:team, name: 'Green Team', event: event)
    role = create(:role, name: 'Envoy', team: team, event: event)
    create(:event_signup, name: 'Sam Scout', email: 'sam@example.com',
                          event: event, team: team, role: role)

    text = pdf_text(described_class.new(event).render)

    expect(text).to include('Present')
    expect(text).to include('Sam Scout')
    expect(text).to include('Envoy')
  end
end
