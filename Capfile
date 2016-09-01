# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Include tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#   https://github.com/capistrano/passenger
#
unless [:bronte, :ac2_prod].include? ARGV[0].to_sym
  require 'capistrano/rvm'
end

require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/passenger'

# Not doing migrations with capistrano for 1.9.3 apps
# require 'capistrano/rails/migrations'
