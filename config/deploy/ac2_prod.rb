# on bernstein, there is no RVM
delete :rvm_ruby_version
# on bernstein, ac2_prod and passenger_prod are identical; latter is in nginx.conf
# and there is no ac2_prod Rails config
set :rails_env, "passenger_prod"
set :application, "ac2"
server 'bernstein.cul.columbia.edu', user: fetch(:remote_user), roles: %w(app db web)
# override deploy_to
set :deploy_to,   "/opt/passenger/#{fetch(:application)}/"
set :remote_user, "deployer"
ask :branch, proc { `git tag --sort=version:refname`.split("\n").last }
set :default_branch, "master"
set :scm_passphrase, "Current user can full owner domains."
