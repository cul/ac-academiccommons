# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '5.2.4.3'

gem 'active-fedora', '~> 8.2'
gem 'addressable'
gem 'blacklight', '~> 6.0'
gem 'blacklight_oai_provider'
gem 'blacklight_range_limit'
gem 'bootsnap'
gem 'bootstrap-sass', '~> 3.3.0'
gem 'cancancan', '~> 2.0'
gem 'cul-ldap'
gem 'cul_omniauth', '~> 0.6.1'
gem 'devise'
gem 'fancybox2-rails' # Used in helper classes. TODO: Confirm that this is needed and used by the application.
gem 'gaffe'
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger', git: 'https://github.com/ruby-grape/grape-swagger', ref: 'da351d0f99228f31329210d21b975a64500e73ab'
gem 'http'
gem 'jbuilder'
gem 'jquery-rails'
gem 'multipart-post', '~>2.0.0'
gem 'nokogiri', '~> 1.10.8'
gem 'okcomputer'
gem 'premailer-rails'
gem 'rainbow'
gem 'resque', '~> 1.27'
gem 'rinku'
gem 'rsolr-ext'
gem 'rubyzip', require: 'zip'
gem 'sass-rails'
gem 'sitemap_generator'
gem 'social-share-button'
gem 'therubyracer'
gem 'turbolinks'
gem 'uglifier'
gem 'unicode'
gem 'voight_kampff'
gem 'webpacker', '~> 4.x'
gem 'whenever', require: false
gem 'wowza-secure_token'

# Database
gem 'mysql2'
gem 'sqlite3', '>= 1.3.5'

group :development do
  gem 'spring'
end

group :development, :test do
  # Deploying by using Capistrano. Using rails, rvm and passenger cap gems as
  # required by our deployment environment.
  gem 'capistrano', '3.8', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-resque', '~> 0.2.2', require: false
  gem 'capistrano-rvm', '~> 0.1', require: false

  gem 'rubocul', '2.0.0', require: false

  gem 'byebug'
  gem 'capybara', '~> 3.0'
  gem 'coveralls', require: false
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'jettywrapper', '>=1.4.0', git: 'https://github.com/samvera-deprecated/jettywrapper.git', branch: 'master'
  gem 'json_spec'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 3.5'
  gem 'selenium-webdriver'
  gem 'solr_wrapper', '>= 0.18.0'
  gem 'webdrivers', '~> 4.0'
  gem 'webmock'
end
