# frozen_string_literal: true

# == Schema Information
#
# Table name: organisers
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_organisers_on_email                 (email) UNIQUE
#  index_organisers_on_reset_password_token  (reset_password_token) UNIQUE
#

# Model for organisers
class Organiser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :organiser_to_events, dependent: :destroy
  has_many :events, through: :organiser_to_events

  # delete events owned by organiser when the organiser is deleted
  before_destroy :destroy_owned_events

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  private

  def destroy_owned_events
    Event.where(organiser_id: id).destroy_all
  end
end
