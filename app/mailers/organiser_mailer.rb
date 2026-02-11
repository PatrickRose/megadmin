# frozen_string_literal: true

# Mailer to send emails to new organiser accounts
class OrganiserMailer < ApplicationMailer
  def organiser_email(organiser, event, url)
    @organiser = organiser
    @event = event
    @url = url

    mail(to: organiser.email, subject: 'An account has been created for you for Pennine Megagames!')
  end
end
