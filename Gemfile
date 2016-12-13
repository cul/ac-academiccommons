source 'https://rubygems.org'

gem 'rails', '4.2.7.1'

# Hydra-Related Gems
gem 'blacklight', '~> 5.19.0'
gem 'rsolr-ext'
gem 'active-fedora', '~>8.2'

gem 'blacklight_oai_provider', '>=0.2.4', :git =>"git@github.com:cul/blacklight_oai_provider.git"
gem 'sqlite3', '>= 1.3.5'
gem 'rinku', '~> 1.3.0', :require => 'rails_rinku'
gem 'garb' # no longer maintained!
gem 'haml', '>= 4.0.7'
gem 'json'
gem 'compass'
gem 'httpclient','~>2.6'
gem 'multipart-post', '~>2.0.0'
gem 'nokogiri', '1.6.0'
gem 'net-ldap', '0.3.1'
gem 'devise'
gem 'cul_omniauth'

# This gem needs to be a requirement of blacklight_oai_provider
gem "oai" #, '>=0.2.5', :git =>"git@github.com:cul/oai-new-valid.git"

gem 'unicode'
gem 'bootstrap-sass'
gem 'mail_form'
gem 'dotenv-rails'

# Locked at jquery-1.7.2; could potentially be updated later.
gem 'jquery-rails', '2.0.3'

gem 'font-awesome-rails'

# Used in helper classes.
# TODO: Confirm that this is needed and used by the application.
gem 'fancybox2-rails'

gem 'sass-rails' #, " ~> 3.2.4"
#gem 'coffee-rails' #, " ~> 3.2.2"
gem 'uglifier'

gem 'mysql', '>= 2.8.1'

gem "therubyracer"

group :development do
  gem 'spring'
end

group :development, :test do
  # Deploying by using Capistrano. Using rails, rvm and passenger cap gems as
  # required by our deployment environment.
  gem 'capistrano', '3.4', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-rvm', '~> 0.1', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false

  gem 'rspec-rails', '~> 3.5'
  gem 'factory_girl_rails'
  gem 'capybara', '~>2.2'
  gem 'poltergeist' # Used to run test with js.
  gem 'database_cleaner'
  gem "jettywrapper", ">=1.4.0"
  gem 'solr_wrapper', '>= 0.18.0'

  gem 'byebug'
end
