require Rails.root.join("config/environments/academiccommons_prod")

AcademicCommons::Application.configure do
  # Print deprecation notices to the stderr
  config.active_support.deprecation = :log

  # Expands the lines which load the assets
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'academiccommons-dev.cdrs.columbia.edu' }

  # Application specific configuration.
  config.analytics_enabled = false
  config.base_path = "academiccommons-dev.cdrs.columbia.edu"
  config.prod_environment = false
end
