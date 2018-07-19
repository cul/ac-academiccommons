Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.action_mailer.delivery_method = :file

  config.default_host = 'http://localhost:3000'

  # Do not compress assets
  #config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Using async queue that does not require any setup
  config.active_job.queue_adapter = :async

end
