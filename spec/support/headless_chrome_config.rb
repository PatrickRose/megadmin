# frozen_string_literal: true

Capybara.register_driver :headless_chrome do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new
  chrome_options.add_argument('--headless') unless ENV['SHOW_CHROME']
  chrome_options.add_argument('--no-sandbox')
  chrome_options.add_argument('--disable-gpu')
  chrome_options.add_argument('--disable-dev-shm-usage')
  chrome_options.add_argument('--disable-infobars')
  chrome_options.add_argument('--disable-extensions')
  chrome_options.add_argument('--disable-popup-blocking')
  chrome_options.add_argument('--window-size=1920,1080')

  chrome_options.add_preference(:download, directory_upgrade: true, prompt_for_download: false,
                                           default_directory: '/tmp')
  chrome_options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  if ENV['SELENIUM_HOST']
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://#{ENV['SELENIUM_HOST']}:#{ENV.fetch('SELENIUM_PORT', nil)}/wd/hub",
      capabilities: chrome_options
    )
  else
    Capybara::Selenium::Driver.new app, browser: :chrome, options: chrome_options
  end
end
Capybara.javascript_driver = :headless_chrome

# Chrome can throw "Node with given id does not belong to the document" (an UnknownError)
# during page transitions. Adding it to invalid_element_errors makes Capybara retry
# instead of failing immediately on this transient CDP race condition.
Capybara::Selenium::Driver.prepend(Module.new do
  def invalid_element_errors
    super + [Selenium::WebDriver::Error::UnknownError]
  end
end)

if ENV['SELENIUM_HOST']
  RSpec.configure do |config|
    config.before(:each, :js) do
      if ENV['SELENIUM_HOST']
        Capybara.app_host = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
      end
    end

    config.after(:each, :js) do
      Capybara.reset_sessions!
      Capybara.use_default_driver
      Capybara.app_host = nil
    end
  end

  Capybara.configure do |config|
    config.server_host = if RUBY_PLATFORM.include?('linux')
                           `/sbin/ip route|awk '/scope/ { print $9 }'`.chomp
                         else
                           '127.0.0.1'
                         end
  end
end
