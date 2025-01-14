lock '3.17.3'

set :instance, 'ac'
set :application, 'academiccommons'
set :deploy_name, "#{fetch(:application)}_#{fetch(:stage)}"

# used to run rake db:migrate, etc
# Default value for :rails_env is fetch(:stage)
set :rails_env, fetch(:deploy_name)
# use the rvm wrapper
set :rvm_custom_path, '~/.rvm-alma8'
set :rvm_ruby_version, fetch(:deploy_name)

set :repo_url,  "git@github.com:cul/ac-academiccommons.git"

set :remote_user, "#{fetch(:instance)}serv"

# Default deploy_to directory is /var/www/:application
set :deploy_to,   "/opt/passenger/#{fetch(:deploy_name)}"

# Default value for :format is :airbrussh
# set :format, :airbrussh

# Default value for linked_dirs is []
set :linked_dirs,
    fetch(:linked_dirs, []).push('log','tmp/pids', 'storage', 'public/feature-logos', 'node_modules', 'public/packs',
                                 'public/sitemaps')

# Default value for keep_releases is 5
set :keep_releases, 3

set :passenger_restart_with_touch, true

set :linked_files, fetch(:linked_files, []).push(
  'config/database.yml',
  'config/solr.yml',
  'config/blacklight.yml',
  'config/fedora.yml',
  'config/secrets.yml',
  'public/robots.txt'
)

# Default value for :log_level is :debug
set :log_level, :info

# NVM Setup, for selecting the correct node version
# NOTE: This NVM configuration MUST be configured before the RVM setup steps because:
# This works:
# nvm exec 16 ~/.rvm-alma8/bin/rvm example_app_dev do node --version
# But this does not work:
# ~/.rvm-alma8/bin/rvm example_app_dev do nvm exec 16 node --version
set :nvm_node_version, fetch(:deploy_name) # This NVM alias must exist on the server
[:rake, :node, :npm, :yarn].each do |command_to_prefix|
  SSHKit.config.command_map.prefix[command_to_prefix].push("nvm exec #{fetch(:nvm_node_version)}")
end

# RVM Setup, for selecting the correct ruby version (instead of capistrano-rvm gem)
set :rvm_ruby_version, fetch(:deploy_name) # This RVM alias must exist on the server
[:rake, :gem, :bundle, :ruby].each do |command_to_prefix|
  SSHKit.config.command_map.prefix[command_to_prefix].push(
    "#{fetch(:rvm_custom_path, '~/.rvm')}/bin/rvm #{fetch(:rvm_ruby_version)} do"
  )
end

set :ssh_options, { forward_agent: true }

# Namespace crontab based on app environment.
set :whenever_identifier, ->{ fetch(:deploy_name) }

namespace :deploy do
  desc "Report the environment"
  task :report do
    run_locally do
      puts "cap called with stage = \"#{fetch(:stage,'none')}\""
      puts "cap would deploy to = \"#{fetch(:deploy_to,'none')}\""
      puts "cap would install from #{fetch(:repo_url)}"
      puts "cap would install in Rails env #{fetch(:rails_env)}"
    end
  end

  desc "Generate dynamic 500.html"
  task :generate_500_html do
    on roles(:web) do |host|
      public_500_html = File.join(release_path, "public", "500.html")
      env = fetch(:stage) == :prod ? fetch(:application) : "#{fetch(:deploy_name).to_s.gsub('_', '-')}.library"
      execute :curl, "https://#{env}.columbia.edu/500", "-sS", "-o", public_500_html
    end
  end

  before :publishing, 'sitemap:create'
  after  :publishing, :generate_500_html
end
