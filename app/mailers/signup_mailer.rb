# frozen_string_literal: true

# Mailer for sending emails to players
class SignupMailer < ApplicationMailer
  def brief_email(user, event, email_note, organiser)
    email = user.email
    @user = user
    @event = event
    @email_note = email_note
    @organiser = organiser

    mail(to: email, subject: "#{event.name} - Pennine Megagames. Event information!")
  end
end
