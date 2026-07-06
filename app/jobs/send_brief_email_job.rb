# frozen_string_literal: true

require 'net/smtp'

# Sends a single signup their brief email.
#
# One job per recipient (rather than one job for the whole event) so that a
# failure only ever retries the affected recipient, instead of re-sending to
# everyone who was already emailed earlier in a batch.
class SendBriefEmailJob < ApplicationJob
  # Seconds to wait before retrying a recipient the provider rate-limited.
  RETRY_WAIT = ENV.fetch('BRIEF_EMAIL_RETRY_WAIT_SECONDS', 60).to_i.seconds

  # Belt-and-braces: if a send still hits the provider's recipient limit, retry
  # that one recipient later rather than dropping them. Safe because sends are
  # per-recipient and brief_emailed_at is only stamped after a successful send,
  # so a retry never produces a duplicate.
  retry_on Net::SMTPServerBusy, wait: RETRY_WAIT, attempts: 10

  class << self
    # Recipients per batch and the gap between batches. Spacing sends keeps us
    # under the provider's per-window recipient limit (Mailgun rejects with a
    # 421 once the limit is exceeded) instead of hitting it and leaning on
    # retries. Tunable via ENV so the window can be matched without a deploy.
    def batch_size
      ENV.fetch('BRIEF_EMAIL_BATCH_SIZE', 20).to_i
    end

    def batch_interval
      ENV.fetch('BRIEF_EMAIL_BATCH_INTERVAL_SECONDS', 60).to_i.seconds
    end

    # Enqueue one job per recipient, spread across batches so we respect the
    # provider's per-window recipient limit.
    def enqueue_all(signups, event, email_note, organiser)
      signups.each_with_index do |signup, index|
        wait = (index / batch_size) * batch_interval
        set(wait: wait).perform_later(signup, event, email_note, organiser)
      end
    end
  end

  def perform(signup, event, email_note, organiser)
    SignupMailer.brief_email(signup, event, email_note, organiser).deliver_now

    # Stamp only after a successful send, so a retry that failed to deliver
    # doesn't leave a misleading timestamp. Deliberately skips validations and
    # callbacks: this is a bookkeeping column, and we don't want a timestamp
    # bump to fail on unrelated validation state on the record.
    signup.update_column(:brief_emailed_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
