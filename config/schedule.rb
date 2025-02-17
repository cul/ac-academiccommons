# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# Our job template wraps the cron job in a script that emails out any errors.
# This is a CUL provided script. More details can be found here:
# https://wiki.library.columbia.edu/display/USGSERVICES/Cron+Management
# Errors will be emailed out to email specified in secrets.yml.
set :email_subject, 'Cron'
set :error_recipient, Rails.application.secrets[:cron_errors]
set :job_template, "/usr/local/bin/mailifrc -s 'Error - :email_subject' :error_recipient -- /bin/bash -l -c ':job'"

# Overriding to remove output redirection option.
job_type :rake, 'cd :path && :environment_variable=:environment bundle exec rake :task'

# Delete searches table daily.
every :day, at: '5am' do
  rake 'blacklight:delete_old_searches[7]', email_subject: 'Searches table cleanout'
end

# Regenerate sitemap every weekday.
every :weekday, at: '6pm' do
  rake 'sitemap:create', email_subject: 'Sitemap generation'
end

# Restart resque workers daily.
every :day, at: '12am' do
  rake 'resque:restart_workers', email_subject: 'Resque workers restart'
end

# Delete stale pending works once a month
every :month do
  rake 'ac:delete_stale_pending_works', email_subject: 'Delete stale pending works'
end

# generate fresh bot user agent list once a month
every :month do
  rake 'ac:bots::generate_list', email_subject: 'Generates bots json at config/crawler-user-agents.json'
end
