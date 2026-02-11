# frozen_string_literal: true

# Base mailer class that other mailers inherit
class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@sheffield.ac.uk'
  layout 'mailer'
end
