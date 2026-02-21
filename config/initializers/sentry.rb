# frozen_string_literal: true

Sentry.init do |config|
  # Sentry is only enabled when SENTRY_DSN is set.
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sample_rate = 1.0
  config.enable_logs = true
  config.before_send = lambda { |event, _hint|
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(event.to_hash)
  }
  config.excluded_exceptions += [
    'ActionController::BadRequest',
    'ActionController::UnknownFormat',
    'ActionController::UnknownHttpMethod',
    'ActionDispatch::Http::MimeNegotiation::InvalidType',
    'CanCan::AccessDenied',
    'Mime::Type::InvalidMimeType',
    'Rack::QueryParser::InvalidParameterError',
    'Rack::QueryParser::ParameterTypeError',
    'SystemExit',
    'URI::InvalidURIError'
  ]
end
