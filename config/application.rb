require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AcademicCommons
  class Application < Rails::Application
    include Cul::Omniauth::FileConfigurable

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be eager loaded.
    # After Rails 5, using autoload_paths is discouraged.
    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.eager_load_paths += Dir[Rails.root.join('app', 'api')]
    config.eager_load_paths += %W(#{config.root}/lib)

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

    # Mapping errors
    config.action_dispatch.rescue_responses.merge!(
      'Blacklight::Exceptions::RecordNotFound' => :record_not_found,
      'CanCan::AccessDenied'                   => :forbidden
    )

    config.active_job.queue_adapter = :inline
    
    config.active_storage.service = :local
  end
end
