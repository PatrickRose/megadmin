# frozen_string_literal: true

# Base class for all application jobs.
class ApplicationJob < ActiveJob::Base
  # Delayed Job uses the same database for its queue, so deferring enqueue
  # until after transaction commit (Rails 7.2 default) is unnecessary.
  self.enqueue_after_transaction_commit = :never

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
