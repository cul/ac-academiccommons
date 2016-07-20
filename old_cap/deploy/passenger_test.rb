set :rails_env, "passenger_test"
set :application, "ac2_test"
set :domain,      "rhys.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :branch, @variables[:branch] || "passenger_test"
set :default_branch, "passenger_prod"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true