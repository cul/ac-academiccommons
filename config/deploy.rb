set :default_stage, "passenger_bl4_dev"
set :stages, %w(passenger_dev passenger_test passenger_prod ac2_bl4_dev ac2_bl4_test)

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'date'

default_run_options[:pty] = true

set :scm, :git
set :repository,  "git@github.com:cul/cul-blacklight-ac2.git"
set :application, "scv"
set :use_sudo, false

set :git_enable_submodules, 1
set :deploy_via, :remote_cache

set :branch do

  tag = Capistrano::CLI.ui.ask "\nPlease, provide a tag name you want to deploy,\notherwise '#{default_branch}' branch will be deployed\nto #{domain}:#{deploy_to}current.\n: "
  if !tag.empty?
     tag
  else
     branch = default_branch
  end

end

namespace :deploy do

  desc "Add tag based on current version"
  task :auto_tag, :roles => :app do
    current_version = IO.read("VERSION").to_s.strip + DateTime.now.strftime("-%m%d%y-%I%M%p")

    tag = Capistrano::CLI.ui.ask "Tag to add: [#{current_version}]}"
    tag = current_version if tag.empty?
 
    system("git tag -a #{tag} -m 'created from branch: #{branch}' && git push origin --tags")
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

after "deploy" do
  run "echo #{branch} > #{deploy_to}shared/relesed_branch_tag.txt"
  run "cp -r #{deploy_to}shared/cached-copy/app/assets/stylesheets/* #{deploy_to}shared/assets/"
  run "cp -r #{deploy_to}shared/cached-copy/app/assets/images/* #{deploy_to}shared/assets/"
  run "cp -r #{deploy_to}shared/cached-copy/app/assets/javascripts/* #{deploy_to}shared/assets/"
end  

after 'deploy:update_code', 'deploy:symlink_shared', 'deploy:create_shared_resources'
