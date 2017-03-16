source 'https://rubygems.org'

gem 'active_model_serializers', '~> 0.10.5'
gem 'addressable', '~> 2.4'
gem 'airbrake', '~> 5.8', '>= 5.8.1'
gem 'aws-sdk', '~> 2.8', '>= 2.8.5'
gem 'bcrypt', '~> 3.1', '>= 3.1.11'
gem 'best_in_place', git: 'https://github.com/bernat/best_in_place.git'
gem 'browser', '~> 2.3'
gem 'daemons', '~> 1.2', '>= 1.2.4'
gem 'data_uri', '~> 0.1.0'
gem 'delayed_job_active_record', '~> 4.1', '>= 4.1.1'
gem 'dynamic_form', '~> 1.1', '>= 1.1.4'
gem 'faraday', '~> 0.11.0'
gem 'faraday-cookie_jar', '~> 0.0.6'
gem 'faraday_middleware', '~> 0.11.0.1'

gem 'sprockets-rails'
gem 'jquery-rails', '~> 4.2', '>= 4.2.2'
gem 'bootstrap-sass', '~> 3.3', '>= 3.3.7'
gem 'json', '~> 2.0', '>= 2.0.3'
#gem 'npm-rails', '~> 0.2.1'

#

gem 'bower', '~> 0.0.5'

#


#
gem 'kaminari', '~> 1.0', '>= 1.0.1'
gem 'kaminari-bootstrap', '~> 3.0.1'

gem 'local_time', '~> 1.0.3'
gem 'meme_captain',
    git: 'https://github.com/mmb/meme_captain.git',
    ref: 'd80fb4b'
gem 'puma', '~> 3.8', '>= 3.8.1'
gem 'rails', '~> 5.0', '>= 5.0.2'
gem 'remote_syslog_logger', '~> 1.0', '>= 1.0.3'
gem 'rmagick',
    '~> 2.15',
    '>= 2.15.4',
    platforms: [:ruby, :mswin],
    require: 'rmagick'
gem 'rmagick4j', '~> 0.3.9', platforms: :jruby, require: 'rmagick'
gem 'rubocop', '~> 0.47.1', require: false
gem 'sqlite3', '~> 1.3', '>= 1.3.13'
gem 'statsd-instrument', '~> 2.1', '>= 2.1.2'
gem 'textacular', '~> 4.0', '>= 4.0.1'
gem 'therubyracer', '~> 0.12.3'
gem 'ttfunk', '~> 1.5'
gem 'twitter_cldr', '~> 4.3'

group :assets do
  gem 'coffee-rails', '~> 4.2', '>= 4.2.1'
  gem 'sass-rails', '~> 5.0', '>= 5.0.6'
  gem 'uglifier', '~> 3.1', '>= 3.1.6'
end

group :production do
  gem 'dalli', '~> 2.7', '>= 2.7.6'
  gem 'pg', '~> 0.20.0'
  gem 'rack-cache', '~> 1.7'
  gem 'rack-rewrite', '~> 1.5.1'
end

group :test do
  gem 'webmock', '~> 2.3', '>= 2.3.2'
end

group :test, :development do
  gem 'capybara', '~> 2.12', '>= 2.12.1'
  gem 'capybara-webkit', '~> 1.12'
  gem 'coffeelint', '~> 1.14'
  gem 'factory_girl_rails', '~> 4.8'
  gem 'jasmine-rails', '~> 0.14.1'
  gem 'rails-controller-testing', '~> 1.0', '>= 1.0.1'
  gem 'rails_best_practices', '~> 1.18'
  # Should not be needed. Workaround described in:
  #   https://github.com/thoughtbot/shoulda-matchers/commit/6a0d0ff12a2c391a809327daa0ad311e5bd7159f
  gem 'rspec', '~> 3.5'
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  gem 'shoulda', '~> 3.5.0'
  gem 'travis', '~> 1.8', '>= 1.8.8', require: false
end
