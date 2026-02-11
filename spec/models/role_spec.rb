# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id       :bigint           not null, primary key
#  name     :string
#  event_id :bigint
#  team_id  :bigint           not null
#
# Indexes
#
#  index_roles_on_event_id          (event_id)
#  index_roles_on_name              (name)
#  index_roles_on_name_and_team_id  (name,team_id) UNIQUE
#  index_roles_on_team_id           (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

require 'rails_helper'

RSpec.describe Role do
  # Set up
  subject(:role) { described_class.new(name: 'Test role', event: @event, team: @team) }

  before do
    @event = create(:event)
    @team = create(:team, event: @event)
    @team2 = create(:team, name: 'Team 2', event: @event)
    @role = create(:role, name: 'ABCD', team: @team, event: @event)
  end

  after do
    described_class.delete_all
    Team.delete_all
    Event.delete_all
  end

  # Validations
  it 'is valid with valid fields' do
    expect(role).to be_valid
  end

  it 'is not valid with nil name' do
    role.name = nil
    expect(role).not_to be_valid
  end

  it 'is not valid with whitespace name' do
    role.name = '   '
    expect(role).not_to be_valid
  end

  it 'is not valid without an event attached' do
    role.event = nil
    expect(role).not_to be_valid
  end

  it 'is not valid without a team attached' do
    role.team = nil
    expect(role).not_to be_valid
  end

  it 'is not valid with name not unique for its team' do
    role.name = 'ABCD'
    expect(role).not_to be_valid
  end

  it 'is valid with name unique for its team' do
    role.name = 'ABCD'
    role.team = @team2
    expect(role).to be_valid
  end

  # Active storage
  it 'allows pdf brief to be attached' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                      content_type: 'application/pdf')
    expect(role.brief).to be_attached
    expect(role).to be_valid
  end

  it 'allows doc brief to be attached' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/doc.doc').open, filename: 'doc.doc',
                      content_type: 'application/msword')
    expect(role.brief).to be_attached
    expect(role).to be_valid
  end

  it 'allows docx brief to be attached' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                      filename: 'docx.docx',
                      content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    expect(role.brief).to be_attached
    expect(role).to be_valid
  end

  it 'doesnt allow txt brief to be attached' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/text.txt').open, filename: 'text.txt',
                      content_type: 'text/plain')
    expect(role).not_to be_valid
  end

  # Create/delete
  it 'saves a valid role' do
    expect { role.save }.to change(described_class, :count).by(1)
  end

  it "doesn't save an unvalid role" do
    role.name = nil
    expect { role.save }.not_to change(described_class, :count)
  end

  it 'deletes a role' do
    role.save
    expect { role.delete }.to change(described_class, :count).by(-1)
  end

  # PDF conversion
  it 'converts a docx brief to pdf' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/docx.docx').open,
                      filename: 'docx.docx',
                      content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    role.save
    role.to_pdf
    expect(role.brief.content_type).to eq('application/pdf')
    expect(role.brief.filename.extension).to eq('pdf')
  end

  it 'ignores a pdf brief when trying to convert to pdf' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/pdf.pdf').open, filename: 'pdf.pdf',
                      content_type: 'application/pdf')
    role.save
    role.to_pdf
    expect(role.brief.content_type).to eq('application/pdf')
    expect(role.brief.filename.extension).to eq('pdf')
  end

  it 'ignores a doc brief when trying to convert to pdf' do
    role.brief.attach(io: Rails.root.join('spec/fixtures/files/doc.doc').open, filename: 'doc.doc',
                      content_type: 'application/msword')
    role.save
    role.to_pdf
    expect(role.brief.content_type).to eq('application/msword')
    expect(role.brief.filename.extension).to eq('doc')
  end
end
