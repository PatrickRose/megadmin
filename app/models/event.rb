# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id                         :bigint           not null, primary key
#  additional_info            :text
#  date                       :datetime
#  description                :text
#  draft                      :boolean
#  google_maps_link           :string
#  location                   :string
#  name                       :string
#  skip_role_brief_validation :boolean          default(FALSE), not null
#  skip_team_brief_validation :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  organiser_id               :bigint
#
# Indexes
#
#  index_events_on_organiser_id  (organiser_id)
#
# Foreign Keys
#
#  fk_rails_...  (organiser_id => organisers.id)
#

# Model for events
class Event < ApplicationRecord
  # Virtual flags set from the edit form to delete attachments on save.
  attr_accessor :remove_rulebook, :remove_additional_document_ids

  has_many :organiser_to_events, dependent: :destroy
  has_many :organisers, through: :organiser_to_events
  has_many :event_signups, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :teams, dependent: :destroy

  has_one_attached :rulebook
  has_many_attached :additional_documents

  # Cached cast-list PDF (player variant). Generated once at email-send time and
  # reused by every player download so we don't launch a headless Chromium per
  # request. Refreshed by CastList#regenerate_player_cast_list!.
  has_one_attached :player_cast_list_pdf

  has_rich_text :timetable
  has_rich_text :description

  validates :name, :date, :location, presence: true
  validates :rulebook,
            content_type: ['application/pdf', 'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  validates :additional_documents,
            content_type: ['application/pdf', 'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document']

  def formatted_name
    name || "Event #{id}"
  end

  # Signups that haven't been fully assigned both a team and a role.
  def signups_missing_assignment
    checklist_signups.select { |signup| signup.team.blank? || signup.role.blank? }
  end

  # Distinct teams assigned to signups that don't have a briefing file attached.
  # We check signup.team (the directly-assigned team) rather than the role's
  # team because that is the brief the player is shown on their play page.
  def teams_missing_briefs
    checklist_signups.filter_map(&:team).uniq.reject { |team| team.brief.attached? }
  end

  # Distinct roles assigned to signups that don't have a briefing file attached.
  def roles_missing_briefs
    checklist_signups.filter_map(&:role).uniq.reject { |role| role.brief.attached? }
  end

  def to_pdf
    # Rulebook
    if rulebook.attached? && rulebook.content_type == 'application/vnd.openxmlformats-officedocument.' \
                                                      'wordprocessingml.document'
      rulebook_pdf = Tempfile.new('rulebook.pdf')
      rulebook_pdf.write(PandocRuby.new([ActiveStorage::Blob.service.path_for(rulebook.key)], from: 'docx').to_pdf)
      rulebook_pdf.rewind
      rulebook.attach(io: rulebook_pdf, filename: 'rulebook.pdf', content_type: 'application/pdf')
      rulebook_pdf.close
      rulebook_pdf.unlink
    end
    # Additional documents
    additional_documents.each do |doc|
      next unless doc.content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'

      doc_filename = doc.filename.base
      doc_pdf = Tempfile.new("#{doc_filename}.pdf")
      doc_pdf.write(PandocRuby.new([ActiveStorage::Blob.service.path_for(doc.key)], from: 'docx').to_pdf)
      doc_pdf.rewind
      additional_documents.attach(io: doc_pdf, filename: "#{doc_filename}.pdf", content_type: 'application/pdf')
      doc.purge
      doc_pdf.close
      doc_pdf.unlink
    end
    save
  end

  private

  # Signups with the associations the checklist walks eager-loaded once (team,
  # role, the role's team, and both brief attachments), so building the checklist
  # never triggers an N+1. Memoised so the three checklist methods share one load.
  def checklist_signups
    @checklist_signups ||= event_signups.includes(team: { brief_attachment: :blob },
                                                  role: [{ brief_attachment: :blob }, :team]).to_a
  end
end
