source 'https://rubygems.org'

gem 'rails', '5.2.0'

gem 'active-fedora', '~> 8.2'
gem 'blacklight', '~> 6.0'
gem 'blacklight_oai_provider'
gem 'blacklight_range_limit'
gem 'bootsnap'
gem 'bootstrap-sass'
gem 'cancancan', '~> 2.0'
gem 'cul-ldap'
gem 'cul_omniauth', git: 'https://github.com/cul/cul_omniauth', branch: 'rails-5'
gem 'devise'
gem 'dotenv-rails'
gem 'fancybox2-rails' # Used in helper classes. TODO: Confirm that this is needed and used by the application.
gem 'gaffe'
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger'
gem 'haml', '>= 4.0.7'
gem 'httpclient','~>2.6'
gem 'jbuilder'
gem 'jquery-rails'
gem 'multipart-post', '~>2.0.0'
gem 'net-ldap'
gem 'nokogiri', '~> 1.8.1'
gem 'okcomputer'
gem 'rainbow'
gem 'rinku', '~> 1.3.0', require: 'rails_rinku'
gem 'rsolr-ext'
gem 'sass-rails'
gem 'sitemap_generator'
gem 'therubyracer'
gem 'turbolinks'
gem 'uglifier'
gem 'unicode'
gem 'voight_kampff'
gem 'whenever', require: false

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
  gem 'capistrano-rvm', '~> 0.1', require: false

  gem 'rubocop', '~> 0.52.1', require: false
  gem 'rubocop-rspec', '~> 1.22.2', require: false

  gem 'byebug'
  gem 'capybara', '~>2.2'
  gem 'chromedriver-helper'
  gem 'coveralls', require: false
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'jettywrapper', '>=1.4.0', git: 'https://github.com/projecthydra/jettywrapper.git', branch: 'master'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 3.5'
  gem 'selenium-webdriver'
  gem 'solr_wrapper', '>= 0.18.0'
end
