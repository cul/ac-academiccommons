# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = 
{
  :address => "localhost",
  :domain => "rowling.cul.columbia.edu",
  :port => 25
}

config.action_controller.relative_url_root = "/ac2_dev"
BASE_PATH = "rowling.cul.columbia.edu"

NEW_DEPOSIT_RECIPIENTS = ["pbf2105@columbia.edu", "patrickforce@gmail.com"]
MAIL_DELIVERER = "pbf2105@columbia.edu"
