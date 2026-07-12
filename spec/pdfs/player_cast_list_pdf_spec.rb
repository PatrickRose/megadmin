# frozen_string_literal: true

require 'rails_helper'
require 'pdf/reader'
require 'stringio'

RSpec.describe PlayerCastListPdf do
  # Extract all text from the generated PDF so we can assert on its content.
  def pdf_text(bytes)
    PDF::Reader.new(StringIO.new(bytes)).pages.flat_map { |page| page.text.split("\n") }.join("\n")
  end

  let(:owner) { create(:organiser, name: 'Olivia Owner', email: 'owner@example.com') }
  let(:event) { create(:event, name: 'Summer Megagame', organiser_id: owner.id) }

  it 'renders a valid PDF document' do
    expect(described_class.new(event).render).to start_with('%PDF')
  end

  it 'shows the event name and its owner' do
    text = pdf_text(described_class.new(event).render)

    expect(text).to include('Summer Megagame')
    expect(text).to include('Olivia Owner')
  end

  it 'lists players grouped by team, with their role' do
    team = create(:team, name: 'Red Team', event: event)
    role = create(:role, name: 'Diplomat', team: team, event: event)
    create(:event_signup, name: 'Pat Player', email: 'pat@example.com',
                          event: event, team: team, role: role)

    text = pdf_text(described_class.new(event).render)

    expect(text).to include('Red Team')
    expect(text).to include('Pat Player')
    expect(text).to include('Diplomat')
  end

  it 'falls back to placeholders for an unassigned team and role' do
    create(:event_signup, name: 'Nomad', email: 'nomad@example.com',
                          event: event, team: nil, role: nil)

    text = pdf_text(described_class.new(event).render)

    expect(text).to include('Unassigned Team')
    expect(text).to include('Unassigned Role')
  end

  it 'notes when the event has no players' do
    text = pdf_text(described_class.new(event).render)

    expect(text).to include('There are no players in this event.')
  end
end
