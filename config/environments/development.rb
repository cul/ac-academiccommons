AcademicCommons::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  config.relative_root = ""
  config.analytics_enabled = false
  
  # this is example of smtp config for local testig via columbian lionmail
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => "smtp.gmail.com",
    :domain => "columbia.edu",
    :user_name => 'you_uni@columbia.edu',
    :password => 'your_device_password',
    :authentication => :login,
    :port => 587,
    :enable_starttls_auto => true
  }

  ################################################## !!!
  
  #config.deposit_notification_bcc = ["cuac@libraries.cul.columbia.edu"]
  config.deposit_notification_bcc = ["ap2972@columbia.edu"]
  config.indexing_report_recipients = ["ap2972@columbia.edu"]
  
  #config.mail_deposit_recipients = ["cuac@libraries.cul.columbia.edu", "ap2972@columbia.edu"]
  config.mail_deposit_recipients = ["ap2972@columbia.edu", "ap2972@columbia.edu"]
  config.mail_deliverer = "ap2972@columbia.edu"
  config.base_path = "localhost:3000"
  

# Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.gem 'blacklight_oai_provider'
  config.gem 'oai'
  
  config.prod_environment = false
  
  config.threadsafe!
end

