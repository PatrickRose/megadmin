# frozen_string_literal: true

# == Schema Information
#
# Table name: event_signups
#
#  id         :bigint           not null, primary key
#  email      :string
#  name       :string
#  uuid       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint
#  role_id    :bigint
#  team_id    :bigint
#
# Indexes
#
#  index_event_signups_on_event_id  (event_id)
#  index_event_signups_on_role_id   (role_id)
#  index_event_signups_on_team_id   (team_id)
#

# Model for player event signups
class EventSignup < ApplicationRecord
  # This is necessary because you can edit an EventSignup and remove the name.
  # Upon doing this, the fields are set to the empty string instead of nil.
  # It needs to be nil so that code like `event_signup.name || 'No name'` works.
  before_validation :normalize_fields

  belongs_to  :role, optional: true
  belongs_to  :team, optional: true
  belongs_to  :event

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: false, presence: true
  validate :email_not_in_use

  # Roles can only be filled once under the same team_id
  validate :role_fulfilled_by_another_player

  def role_fulfilled_by_another_player
    return if role_id.nil?

    existing_signup = EventSignup.where(role_id: role_id, team_id: team_id).first
    return if existing_signup.nil? || existing_signup == self

    errors.add(:base,
               "The role '#{existing_signup.role.name}' is already fulfilled by '#{existing_signup.name}' " \
               'on this team.')
  end

  def email_not_in_use
    existing_email_signup = EventSignup.where(event_id: event_id, email: email).first
    return if existing_email_signup.nil? || existing_email_signup == self

    errors.add(:base, "The email '#{email}' is already in use by '#{existing_email_signup.name}'.")
  end

  def normalize_fields
    self.name = nil if name.blank?
  end
end
