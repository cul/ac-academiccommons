require 'active_support/core_ext/integer/time'

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading con boot to mimic production environment.
  # Test might slow down a bit, but we need to mimic production as best as we can.
  config.eager_load = true

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false # Setting to false for error page tests
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Do not compress assets
  # config.assets.compress = false

  config.action_mailer.perform_caching = false
  # Expands the lines which load the assets
  config.assets.debug = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log
  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Render exception templates instead of raising exceptions (custom).
  config.action_dispatch.show_exceptions = true

  # ActiveJob test environment
  config.active_job.queue_adapter = :test

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  config.default_host = 'http://localhost:3000'

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
end
