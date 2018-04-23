class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config_for(:emails)['mail_deliverer']
  layout 'mailer'
end
