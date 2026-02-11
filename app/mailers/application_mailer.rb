# frozen_string_literal: true

# Base mailer class that other mailers inherit
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM', 'no-reply@megadmin.patrickrosemusic.co.uk')
  layout 'mailer'
end
