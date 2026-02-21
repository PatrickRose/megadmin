# frozen_string_literal: true

# Ensure the Azure Storage container exists in the Azurite emulator for local development.
if Rails.env.development?
  Rails.application.config.after_initialize do
    require 'azure_blob'

    client = AzureBlob::Client.new(
      account_name: ENV['AZURE_STORAGE_ACCOUNT_NAME'],
      access_key: ENV['AZURE_STORAGE_ACCESS_KEY'],
      container: ENV.fetch('AZURE_STORAGE_CONTAINER', 'activestorage'),
      host: ENV['AZURE_STORAGE_BLOB_HOST']
    )
    client.create_container
  rescue StandardError => e
    Rails.logger.info "Azure Storage container setup: #{e.message}"
  end
end
