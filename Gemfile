source 'https://rubygems.org'

gem 'rails', '4.2.8'

# Hydra-Related Gems
gem 'active-fedora', '~> 8.2'
gem 'blacklight', '~> 6.0'
gem 'rsolr-ext'
gem 'blacklight_oai_provider'

# Database
gem 'mysql2'
gem 'sqlite3', '>= 1.3.5'

gem 'bootstrap-sass'
gem 'cul_omniauth'#, git: 'https://github.com/cul/cul_omniauth', branch: 'rails-5'
gem 'cul-ldap'
gem 'devise'
gem 'dotenv-rails'
gem 'fancybox2-rails' # Used in helper classes. TODO: Confirm that this is needed and used by the application.
gem 'gaffe'
gem 'haml', '>= 4.0.7'
gem 'httpclient','~>2.6'
gem 'jquery-rails'
gem 'mail_form'
gem 'multipart-post', '~>2.0.0'
gem 'net-ldap'
gem 'nokogiri', '~> 1.8.1'
gem 'okcomputer'
gem 'rainbow'
gem 'rinku', '~> 1.3.0', require: 'rails_rinku'
gem 'sass-rails'
gem 'therubyracer'
gem 'turbolinks'
gem 'uglifier'
gem 'unicode'
gem 'voight_kampff'
gem 'whenever', require: false

group :development do
  gem 'spring'
end

group :development, :test do
  # Deploying by using Capistrano. Using rails, rvm and passenger cap gems as
  # required by our deployment environment.
  gem 'capistrano', '3.8', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-rvm', '~> 0.1', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false

  gem 'rubocop', '~> 0.52.1', require: false
  gem 'rubocop-rspec', '~> 1.22.2', require: false

  gem 'byebug'
  gem 'capybara', '~>2.2'
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'jettywrapper', '>=1.4.0', git: 'https://github.com/projecthydra/jettywrapper.git', branch: 'master'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'rspec-rails', '~> 3.5'
  gem 'rspec-its'
  gem 'solr_wrapper', '>= 0.18.0'
end
