# frozen_string_literal: true

ruby File.read('.ruby-version').strip

source 'https://rubygems.org'

gem 'rails', '~> 6.1.7.10'

gem 'active-fedora', '~> 8.7'
gem 'active-triples', git: 'https://github.com/cul/ActiveTriples', branch: 'deprecation_update'
gem 'addressable'
gem 'blacklight', '~> 7.29'
gem 'blacklight_oai_provider'
gem 'blacklight_range_limit',
    git: 'https://github.com/JackBlackLight/blacklight_range_limit.git', branch: 'use_blacklight_component'
gem 'bootsnap'
gem 'cancancan'
gem 'concurrent-ruby', '1.3.4' # TODO: this is temporary for updating to rails 6.0.6
gem 'cul-ldap'
gem 'cul_omniauth', '>= 0.7.0'
gem 'deprecation', '>= 1.1.0'
gem 'devise' # consider pinning
gem 'fancybox2-rails' # Used in helper classes. TODO: Confirm that this is needed and used by the application.
gem 'gaffe'
gem 'grape', '>= 1.8.0'
gem 'grape-entity', '>= 1.0.0'
# pinning swagger to commit that supports braces in array params; functionality is broken in next version - 0.31.0
# gem 'grape-swagger', git: 'https://github.com/ruby-grape/grape-swagger', ref: 'da351d0f99228f31329210d21b975a64500e73ab'
gem 'grape-swagger', '~>0.32.0'
gem 'mustermann', '~> 2.0'

# gem 'mustermann-grape', '~> 1.1'
gem 'http'
gem 'jbuilder'
gem 'jquery-rails'
gem 'mail', '~> 2.8'
gem 'multipart-post', '~>2.0.0'
gem 'net-scp', '~> 4.0.0'
gem 'net-ssh', '~> 7.2.0'
gem 'nokogiri', '~> 1.15.2'
gem 'okcomputer'
gem 'premailer-rails'
gem 'rainbow'
gem 'resque', '~> 2.7.0'
gem 'rinku'
gem 'rsolr-ext'
gem 'rubyzip', require: 'zip'
gem 'sitemap_generator'
gem 'turbolinks'
gem 'uglifier'
gem 'unicode'
gem 'voight_kampff', '~>2.0', require: 'voight_kampff/rails'
gem 'webpacker', '~> 5.4.0'
gem 'whenever', require: false
gem 'will_paginate'
gem 'wowza-secure_token'
# Database
gem 'mysql2', '>= 0.5.6'
gem 'sqlite3', '~> 1.4'

group :development do
  gem 'listen'
  gem 'spring'
end

group :development, :test do
  # Deploying by using Capistrano. Using rails, rvm and passenger cap gems as
  # required by our deployment environment.
  gem 'capistrano', '~> 3.17.3', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-passenger', '~> 0.2', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-resque', '= 0.2.1', require: false

  gem 'rubocul', '~> 4.0', require: false

  gem 'byebug'
  gem 'capybara', '~> 3.39'
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'jettywrapper', '>=1.4.0', git: 'https://github.com/samvera-deprecated/jettywrapper.git', branch: 'master'
  gem 'json_spec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'selenium-webdriver', '~> 4.11'
  gem 'simplecov', '>= 0.22.0', require: false
  gem 'solr_wrapper', '~> 4.0'
  gem 'webmock'
end

# Use Puma for local development
gem 'puma', '~> 5.2'
