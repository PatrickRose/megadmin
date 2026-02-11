# frozen_string_literal: true

# Job class for asynchronous email sending
class SendEmailsJob < ApplicationJob
  def perform(*args)
    string_signups, event_string, email_note, organiser_string = args

    locator = GlobalID::Locator

    event = locator.locate(event_string)
    organiser = locator.locate(organiser_string)

    signups = string_signups.map { |id| locator.locate(id) }

    signups.each_slice(10) do |i|
      i.each do |j|
        SignupMailer.brief_email(j, event, email_note, organiser).deliver
      end
      sleep 3
    end
  end
end
