class ErrorMailer < ApplicationMailer
  # This mailer contains emails that go to the Academic Commons
  # development staff.
  default from: Rails.application.config_for(:emails)['mail_deliverer']
  default to:   Rails.application.config_for(:emails)['error_notifications']

  def sword_deposit_error(message)
    send_error_to_developers('Error Delivering SWORD Deposit', message)
  end

  def send_error_to_developers(subject, message)
    @message = message
    mail(subject: subject, template_name: 'send_error_to_developers')
  end
end
