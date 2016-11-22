set :remote_user, "cdrsserv"
set :deploy_name, "#{fetch(:application)}_prod"
set :deploy_to,   "/opt/passenger/cdrs/#{fetch(:deploy_name)}"
set :rails_env, fetch(:deploy_name)
set :rvm_ruby_version, fetch(:deploy_name)

server "cdrs-nginx-prod1.cul.columbia.edu", user: fetch(:remote_user), roles: %w(app db web)
# In test/prod, deploy from release tags; most recent version is default
ask :branch, proc { `git tag --sort=version:refname`.split("\n").last }
