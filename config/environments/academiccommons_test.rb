require Rails.root.join("config/environments/academiccommons_prod")

AcademicCommons::Application.configure do
  # Expands the lines which load the assets
  config.assets.debug = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'academiccommons-test.library.columbia.edu' }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  config.active_job.queue_adapter = :resque

  # Application specific configuration.
  config.analytics_enabled = false
  config.default_host = 'https://academiccommons-test.library.columbia.edu'
  config.prod_environment = false
  config.sending_deposits_to_sword = true
end
