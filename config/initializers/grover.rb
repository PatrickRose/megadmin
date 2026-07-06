# frozen_string_literal: true

# https://github.com/Studiosity/grover/?tab=readme-ov-file#configuration
Grover.configure do |config|
  config.options = {
    # --disable-dev-shm-usage: containers (e.g. Azure Container Apps) give Chrome
    # a tiny /dev/shm; without this Chrome can crash on launch. It falls back to
    # /tmp for shared memory instead.
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  }
end
