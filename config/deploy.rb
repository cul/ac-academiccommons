set :default_stage, "passenger_dev"
set :stages, %w(passenger_dev passenger_test passenger_prod)

require 'capistrano/ext/multistage'
default_run_options[:pty] = true

set :scm, :git
set :repository,  "git@github.com:cul/cul-blacklight-ac2.git"
set :application, "scv"
set :use_sudo, false

namespace :deploy do
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
  end
  
end


after 'deploy:update_code', 'deploy:symlink_shared', 'deploy:create_shared_resources'
