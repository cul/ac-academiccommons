source 'https://rubygems.org'

gem 'rails', '4.2.7.1'

# Hydra-Related Gems
gem 'blacklight', '~> 5.19.0'
gem 'active-fedora', '~>8.2'

gem 'blacklight_oai_provider', '>=0.2.4', :git =>"git@github.com:cul/blacklight_oai_provider.git"
gem 'rake', '~> 10.0.0'
gem 'sqlite3', '>= 1.3.5'
gem 'rinku', '~> 1.3.0', :require => 'rails_rinku'
gem 'authlogic'
gem 'authlogic_wind'
gem 'cul-fedora', '~> 1.0.3'
gem 'garb' # no longer maintained!
gem 'googlecharts'
gem 'haml', '>= 4.0.7'
gem 'json'
gem 'compass'
gem 'httpclient','~>2.6'
gem 'multipart-post', '~>2.0.0'
gem 'nokogiri', '1.6.0'
gem 'net-ldap', '0.3.1'
gem 'net-ssh', '2.9.4'

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

gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'mysql', '>= 2.8.1'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
# Use Capistrano for deployment
  gem 'capistrano', '3.4', require: false
# Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm', '~> 0.1', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger', '~> 0.1', require: false
  gem 'rspec-rails', '~> 3.5'
  gem 'capybara', '~>2.2'
  gem 'poltergeist' # Used to run test with js.
  gem 'database_cleaner'
  gem "jettywrapper", ">=1.4.0"
end
