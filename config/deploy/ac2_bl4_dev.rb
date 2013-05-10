set :rails_env, "ac2_bl4_dev"
set :application, "ac2_bl4_dev"
set :domain,      "bronte.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :branch, @variables[:branch] || "ac2_bl4_dev"
set :default_branch, "ac2_bl4_dev"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true