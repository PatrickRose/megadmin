# frozen_string_literal: true

# https://github.com/Studiosity/grover/?tab=readme-ov-file#configuration
Grover.configure do |config|
  config.options = {
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
end
