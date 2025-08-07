class AdministrativeMailer < ApplicationMailer
  # This mailer contains emails that go to the Academic Commons
  # administrative staff.
  default to: Rails.application.config_for(:emails)[:administrative_notifications]

  # Notification is sent to AC staff when a new agreement is signed.
  def new_agreement(name, email, agreement_version)
    @name = name
    @email = email
    @agreement_version = agreement_version

    mail(subject: 'Academic Commons Author Agreement Accepted')
  end

  def new_deposit(deposit)
    @deposit = deposit

    subject = 'SD'
    subject.concat(" #{@deposit.uni} -") if @uni
    subject.concat(" #{@deposit.title.truncate(50)}")

    mail(subject: subject)
  end
end
