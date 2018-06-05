class NotificationMailer < ApplicationMailer
  helper :catalog # Needed to correctly render persistent url.

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
end
