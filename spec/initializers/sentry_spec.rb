# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentry do
  it 'sends Rails structured logs to Sentry' do
    expect(described_class.configuration.rails.structured_logging).to be_enabled
  end
end
