# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.3'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 8.0'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'base64'
gem 'bootsnap', require: false
gem 'drb', require: false
gem 'mutex_m', require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing'
gem 'ruby-vips'

gem 'activerecord-session_store'
gem 'hamlit'
gem 'hamlit-rails'

gem 'simple_form'

gem 'draper'

gem 'shakapacker'

gem 'cancancan'
gem 'devise'

gem 'daemons'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'whenever'

gem 'sanitize'
gem 'sanitize_email'

# stackprof must load before the Sentry SDK for profiling to hook in, so the
# ordering here is deliberate rather than alphabetical.
# rubocop:disable Bundler/OrderedGems
gem 'stackprof'
gem 'sentry-rails'
gem 'sentry-ruby'
# rubocop:enable Bundler/OrderedGems

gem 'csv'

gem 'active_storage_validations'

gem 'azure-blob'

gem 'rubyzip', require: 'zip'
gem 'tempfile'

gem 'concurrent-ruby', '1.3.7'

gem 'pandoc-ruby'

group :development do
  gem 'annotaterb'
  gem 'brakeman'
  gem 'bundler-audit'
  gem 'letter_opener'
  gem 'ruby-lsp'
  gem 'web-console'
end

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'rspec-rails'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'pdf-reader'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov'
end

# Grover (headless Chromium) renders the Google Docs -> PDF briefs, where we need
# a full browser to lay out arbitrary published-doc HTML. The cast list, being
# plain tabular data we control, is rendered by Prawn instead (no browser).
gem 'grover', '~> 1.2'
gem 'prawn'
gem 'prawn-table'

gem 'rubocop', '~> 1.88'
gem 'rubocop-capybara'
gem 'rubocop-factory_bot'
gem 'rubocop-haml'
gem 'rubocop-performance'
gem 'rubocop-rails'
gem 'rubocop-rspec'
gem 'rubocop-rspec_rails'
