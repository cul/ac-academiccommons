Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Caching classes on test in order to mimic a production environment.
  config.cache_classes = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false # Setting to false for error page tests
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Do not compress assets
  # config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Eager loading con boot to mimic production environment.
  # Test might slow down a bit, but we need to mimic production as best as we can.
  config.eager_load = true

  # ActiveStorage test environment.
  config.active_storage.service = :test

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  config.default_host = 'http://localhost:3000'
end
