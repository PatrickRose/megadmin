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

# Model for player roles
class Role < ApplicationRecord
  # Associations
  belongs_to :event
  belongs_to :team
  has_many :event_signups, dependent: nil

  # Validations
  validates :name, presence: true, allow_blank: false,
                   uniqueness: { scope: :team, message: 'must be unique within a team.' }
  validates :brief, content_type: ['application/pdf', 'application/msword',
                                   'application/vnd.openxmlformats-officedocument.wordprocessingml.document']

  # Active storage
  has_one_attached :brief

  # Private methods

  def name_brief
    if brief.attached?
      name
    else
      "#{name} [NO BRIEF]"
    end
  end

  def to_pdf
    unless brief.attached? && brief.content_type == 'application/vnd.openxmlformats-officedocument' \
                                                    '.wordprocessingml.document'
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
