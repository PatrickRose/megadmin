# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id       :bigint           not null, primary key
#  name     :string
#  event_id :bigint
#
# Indexes
#
#  index_teams_on_event_id           (event_id)
#  index_teams_on_event_id_and_name  (event_id,name) UNIQUE
#  index_teams_on_name               (name)
#
require 'rails_helper'

RSpec.describe Team do
  # Set up
  subject(:team) { described_class.new(name: 'Test team', event: @event) }

  before do
    @event = create(:event)
  end

  after do
    Event.delete_all
  end

  # Validations
  it 'is valid with valid fields' do
    expect(team).to be_valid
  end

  it 'is not valid with nil name' do
    team.name = nil
    expect(team).not_to be_valid
  end

  it 'is not valid with whitespace name' do
    team.name = '   '
    expect(team).not_to be_valid
  end

  it 'is not valid without an event attached' do
    team.event = nil
    expect(team).not_to be_valid
  end

  # Active storage
  it 'allows jpg image to be attached' do
    team.image.attach(io: Rails.root.join('spec/fixtures/files/image.jpg').open,
                      filename: 'image.jpg', content_type: 'image/jpeg')
    expect(team.image).to be_attached
    expect(team).to be_valid
  end

  it 'allows png image to be attached' do
    team.image.attach(io: Rails.root.join('spec/fixtures/files/image.png').open,
                      filename: 'image.png', content_type: 'image/png')
    expect(team.image).to be_attached
    expect(team).to be_valid
  end

  it 'does not allow a txt file to be attached as the image' do
    team.image.attach(io: Rails.root.join('spec/fixtures/files/text.txt').open, filename: 'text.txt',
                      content_type: 'text/plain')
    expect(team).not_to be_valid
  end

  it 'allows pdf brief to be attached' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                      content_type: 'application/pdf')
    expect(team.brief).to be_attached
    expect(team).to be_valid
  end

  it 'allows doc brief to be attached' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/doc.doc').open, filename: 'doc.doc',
                      content_type: 'application/msword')
    expect(team.brief).to be_attached
    expect(team).to be_valid
  end

  it 'allows docx brief to be attached' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                      filename: 'docx.docx',
                      content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    expect(team.brief).to be_attached
    expect(team).to be_valid
  end

  it 'does not allow txt brief to be attached' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/text.txt').open, filename: 'text.txt',
                      content_type: 'text/plain')
    expect(team).not_to be_valid
  end

  # Create/delete
  it 'saves a valid team' do
    expect { team.save }.to change(described_class, :count).by(1)
  end

  it "doesn't save an unvalid team" do
    team.name = nil
    expect { team.save }.not_to change(described_class, :count)
  end

  it 'deletes a team' do
    team.save
    expect { team.delete }.to change(described_class, :count).by(-1)
  end

  # name_brief
  it 'returns the name when brief is attached' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                      content_type: 'application/pdf')
    expect(team.name_brief).to eq('Test team')
  end

  it 'returns "name [NO BRIEF]" when brief is not attached' do
    expect(team.name_brief).to eq('Test team [NO BRIEF]')
  end

  # PDF conversion
  it 'converts a docx brief to pdf' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                      filename: 'docx.docx',
                      content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    team.save
    team.to_pdf
    expect(team.brief.content_type).to eq('application/pdf')
    expect(team.brief.filename.extension).to eq('pdf')
  end

  it 'ignores a pdf brief when trying to convert to pdf' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                      content_type: 'application/pdf')
    team.save
    team.to_pdf
    expect(team.brief.content_type).to eq('application/pdf')
    expect(team.brief.filename.extension).to eq('pdf')
  end

  it 'ignores a doc brief when trying to convert to pdf' do
    team.brief.attach(io: Rails.root.join('spec/fixtures/files/doc.doc').open, filename: 'doc.doc',
                      content_type: 'application/msword')
    team.save
    team.to_pdf
    expect(team.brief.content_type).to eq('application/msword')
    expect(team.brief.filename.extension).to eq('doc')
  end
end
