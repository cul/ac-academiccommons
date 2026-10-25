# frozen_string_literal: true

require Rails.root.join('config/environments/deployed')

AcademicCommons::Application.configure do
  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'academiccommons-semantic-beta.library.columbia.edu' }

  config.log_level = :debug

  config.active_job.queue_adapter = :resque

  # Application specific configuration.
  config.analytics_enabled = false
  config.default_host = 'https://academiccommons-semantic-beta.library.columbia.edu'
  config.hosts << 'academiccommons-semantic-beta.library.columbia.edu'
  config.prod_environment = false
  config.sending_deposits_to_sword = false
end
