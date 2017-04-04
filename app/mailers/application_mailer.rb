class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.emails['mail_deliverer']
  layout 'mailer'
end
