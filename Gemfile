source 'https://rubygems.org'

gem 'rails', '3.2.13'

# Hydra-Related Gems
gem 'blacklight', '~> 4.0'
gem "rsolr",  :git =>"git@github.com:cul/rsolr.git"

gem 'blacklight_advanced_search'
gem 'blacklight_oai_provider', '>=0.2.4', :git =>"git@github.com:cul/blacklight_oai_provider.git"
gem 'rake', '~> 10.0.0'
gem 'rack', '1.4.5'
gem 'sqlite3', '>= 1.3.5'
gem 'actionpack', '3.2.13'
gem 'railties', '3.2.13'
gem 'kaminari', '0.13.0'
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
gem "oai", '>=0.2.5', :git =>"git@github.com:cul/oai-new-valid.git"
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

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', " ~> 3.2.4"
  gem 'coffee-rails', " ~> 3.2.2"
  gem 'uglifier'
end

# Use unicorn as the web server
# gem 'unicorn'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'mysql', '>= 2.8.1'

# gem 'aws-s3', :require => 'aws/s3'

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
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara', '~>2.2'
  gem 'poltergeist' # Used to run test with js.
  gem "jettywrapper", ">=1.4.0"
end
