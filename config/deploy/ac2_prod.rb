set :rails_env, "ac2_prod"
set :application, "ac2"
set :domain,      "bernstein.cul.columbia.edu"
set :deploy_to,   "/opt/passenger/#{application}/"
#set :deploy_to,   "/opt/passenger/ac2/"
set :user, "deployer"
set :branch, @variables[:branch] || "ac2_prod"
set :default_branch, "ac2_prod"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true