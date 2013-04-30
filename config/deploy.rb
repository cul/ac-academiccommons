set :default_stage, "passenger_bl4_dev"
set :stages, %w(passenger_dev passenger_test passenger_prod passenger_bl4_dev passenger_bl4_test ac2_bl4_dev)

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'date'


default_run_options[:pty] = true


set :branch do
  default_tag = `git tag`.split("\n").last
 
  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

set :scm, :git
set :repository,  "git@github.com:cul/cul-blacklight-ac2.git"
set :application, "scv"
set :use_sudo, false

set :git_enable_submodules, 1
set :deploy_via, :remote_cache

namespace :deploy do

  desc "Add tag based on current version"
  task :auto_tag, :roles => :app do
    current_version = IO.read("VERSION").to_s.strip + DateTime.now.strftime("-%m%d%y-%I%M%p")
    tag = Capistrano::CLI.ui.ask "Tag to add: [#{current_version}] "
    tag = current_version if tag.empty?
 
    system("git tag -a #{tag} -m '#{rails_env}' && git push origin --tags")
  end
 

  desc "Restart Application"
  task :restart, :roles => :app do
    run "mkdir -p #{current_path}/tmp/cookies"
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/solr.yml #{release_path}/config/solr.yml"
    run "ln -nfs #{deploy_to}shared/fedora.yml #{release_path}/config/fedora.yml"
    run "rm -rf #{release_path}/data/self-deposit-uploads"
    run "ln -nfs #{deploy_to}shared/self-deposit-uploads #{release_path}/data/self-deposit-uploads"
  end

  task :create_shared_resources do
    run "mkdir -p #{deploy_to}shared/log/ac-indexing"
    run "mkdir -p #{deploy_to}shared/self-deposit-uploads"
  end
  
end


after 'deploy:update_code', 'deploy:symlink_shared', 'deploy:create_shared_resources'
