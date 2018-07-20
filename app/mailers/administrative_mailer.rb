class AdministrativeMailer < ApplicationMailer
  # This mailer contains emails that should go to the Academic Commons
  # administrative staff.
  default to: Rails.application.config_for(:emails)['administrative_notifications']

  def new_deposit(deposit)
    @deposit = deposit

    subject = 'SD'
    subject.concat(" #{@uni} -") if @uni
    subject.concat(" #{@title.truncate(50)}")

    mail(subject: subject)
  end
end
