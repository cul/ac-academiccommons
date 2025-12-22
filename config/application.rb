require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AcademicCommons
  class Application < Rails::Application
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    #

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[tasks])
    # N.B. The autoload_paths contains app/** (** = subdirectories) except
    #      assets/, javascript/, and views/ by default. The above config adds
    #      lib/** to autoload_paths, except what we ignore.
    #      The eager_load_paths contains app/ and all subdirectories by default.
    #      Engines will also add to these paths as neede during initialization.

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new

    # Always throw errors if there is a problem sending an email.
    config.action_mailer.raise_delivery_errors = true

    ### Application specific configuration.
    config.prod_environment = false

    # Analytics disabled by default. Google analytics should be enabled in a
    # per-environment basis.
    config.analytics_enabled = false

    # Only sending deposits to SWORD in certain environments.
    config.sending_deposits_to_sword = false

    # Mapping errors
    config.action_dispatch.rescue_responses.merge!(
      'Blacklight::Exceptions::RecordNotFound' => :not_found,
      'CanCan::AccessDenied'                   => :forbidden
    )

    # Using async queue that does not require any setup
    config.active_job.queue_adapter = :async

    config.active_storage.service = :local

    config.embedding_service = config_for(:embedding_service)

    # Disable assets (sprockets) for actiontext (will be handled by vite)
    config.action_text.embed_assets = false
  end
end
