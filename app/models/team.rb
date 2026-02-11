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

# Model for player teams
class Team < ApplicationRecord
  # Associations
  belongs_to :event
  has_many :event_signups, dependent: nil
  has_many :roles, dependent: :destroy

  # Validations
  validates :name, presence: true, allow_blank: false,
                   uniqueness: { scope: :event_id, message: 'has already been taken for this event' }
  validates :image, content_type: %r{\Aimage/.*\z}
  validates :brief,
            content_type: ['application/pdf', 'application/msword',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document']

  # Active storage
  has_one_attached :brief
  has_one_attached :image

  # Private methods

  def name_brief
    if brief.attached?
      name
    else
      "#{name} [NO BRIEF]"
    end
  end

  def to_pdf
    unless brief.attached? && brief.content_type == 'application/vnd.openxmlformats-officedocument.' \
                                                    'wordprocessingml.document'
      return
    end

    brief_pdf = Tempfile.new('brief.pdf')
    brief_pdf.write(PandocRuby.new([ActiveStorage::Blob.service.path_for(brief.key)], from: 'docx').to_pdf)
    brief_pdf.rewind
    brief.attach(io: brief_pdf, filename: 'brief.pdf', content_type: 'application/pdf')
    brief_pdf.close
    brief_pdf.unlink
    save
  end
end
