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

# Model for events
class Event < ApplicationRecord
  has_many :organiser_to_events, dependent: :destroy
  has_many :organisers, through: :organiser_to_events
  has_many :event_signups, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :teams, dependent: :destroy

  has_one_attached :rulebook
  has_many_attached :additional_documents

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
end
