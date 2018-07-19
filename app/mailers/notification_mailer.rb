class NotificationMailer < ApplicationMailer
  helper :catalog # Needed to correctly render persistent url.
  default from: 'ac@columbia.edu'

  def new_item_available(solr_doc, uni, email, name = nil)
    @uni, @name, @email = uni, name, email
    @solr_doc = solr_doc

    subject = (@solr_doc.embargoed?) ?
                'Your work is now registered in Academic Commons' :
                'Your work is now available in Academic Commons'

    bcc = Rails.application.config_for(:emails)['deposit_notification_bcc']

    if Rails.application.config.prod_environment
      mail(to: @email, bcc: bcc, subject: subject)
      logger.info "New item notification was sent to: #{@email}, bcc: #{bcc}"
    else
      subject = "#{subject} - #{Rails.env.upcase}"
      mail(to: bcc, subject: subject)
      logger.info "New item notification was sent to: #{bcc}"
    end
  end

  # Notification is sent to AC staff when a new agreement is signed.
  def new_agreement(name, email, agreement_version)
    @name = name
    @email = email
    @agreement_version = agreement_version
    recipients = Rails.application.config_for(:emails)['new_agreement_notification']
    from = Rails.application.config_for(:emails)['mail_deliverer']
    subject = 'Academic Commons Author Agreement Accepted'
    content_type = 'text/html'

    mail(to: recipients, from: from, subject: subject, content_type: content_type)
  end

  # Sent signed agreement link for a user without CU authentication to sign agreement.
  def request_for_agreement(name, email, token)
    @token = token
    @name = name
    from = Rails.application.config_for(:emails)['mail_deliverer']
    subject = 'Signature request: Columbia Academic Commons participation agreement'

    mail(to: email, from: from, subject: subject)
  end

  # Notification sent out to self-identified student depositors. This
  # notification serves as a reminder that departmental approval is required
  # for student works.
  def reminder_to_request_departmental_approval(name, email)
    @name = name

    from = Rails.application.config_for(:emails)['mail_deliverer']
    subject = 'Request Department Approval'

    mail(to: email, from: from, subject: subject)
  end

  def deposit_sent_to_sword(deposit, email)
    @deposit = deposit
    mail(to: email, subject: 'Deposit sent to sword')
  end
end
