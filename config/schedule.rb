# frozen_string_literal: true

#####
#
# These are required to make rvm work properly within crontab
#
if ENV['MY_RUBY_HOME']&.include?('rvm')
  env 'PATH',         ENV.fetch('PATH', nil)
  env 'GEM_HOME',     ENV.fetch('GEM_HOME', nil)
  env 'MY_RUBY_HOME', ENV['MY_RUBY_HOME']
  env 'GEM_PATH',
      ENV['_ORIGINAL_GEM_PATH'] || ENV['BUNDLE_ORIG_GEM_PATH'] || ENV.fetch('BUNDLER_ORIG_GEM_PATH', nil)
end
#
#####
