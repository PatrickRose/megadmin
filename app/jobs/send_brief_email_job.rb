# frozen_string_literal: true

# Sends a single signup their brief email.
#
# One job per recipient (rather than one job for the whole event) so that a
# failure only ever retries the affected recipient, instead of re-sending to
# everyone who was already emailed earlier in a batch.
class SendBriefEmailJob < ApplicationJob
  def perform(signup, event, email_note, organiser)
    SignupMailer.brief_email(signup, event, email_note, organiser).deliver_now

    # Stamp only after a successful send, so a retry that failed to deliver
    # doesn't leave a misleading timestamp. Deliberately skips validations and
    # callbacks: this is a bookkeeping column, and we don't want a timestamp
    # bump to fail on unrelated validation state on the record.
    signup.update_column(:brief_emailed_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
