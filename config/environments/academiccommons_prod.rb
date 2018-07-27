AcademicCommons::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Compresses assets.
  config.assets.compress = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # Reducing logging in production.
  config.log_level = :warn

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => ENV['SMTP_ADDRESS'],
    :domain => ENV['SMTP_DOMAIN'],
    :port => ENV['SMTP_PORT']
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Log deprecation notices.
  config.active_support.deprecation = :log

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'academiccommons.columbia.edu' }

  # Application specific configuration.
  config.analytics_enabled = true
  config.default_host = 'academiccommons.columbia.edu'
  config.prod_environment = true
  config.sending_deposits_to_sword = true
end
