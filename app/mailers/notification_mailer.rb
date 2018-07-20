class NotificationMailer < ApplicationMailer
  helper :catalog # Needed to correctly render persistent url.
  default from: Rails.application.config_for(:emails)['mail_deliverer']

  def new_item_available(solr_doc, uni, email, name = nil)
    @uni, @name, @email = uni, name, email
    @solr_doc = solr_doc

    subject = (@solr_doc.embargoed?) ?
                'Your work is now registered in Academic Commons' :
                'Your work is now available in Academic Commons'

    bcc = Rails.application.config_for(:emails)['administrative_notifications']

    if Rails.application.config.prod_environment
      mail(to: @email, bcc: bcc, subject: subject)
      logger.info "New item notification was sent to: #{@email}, bcc: #{bcc}"
    else
      subject = "#{subject} - #{Rails.env.upcase}"
      mail(to: bcc, subject: subject)
      logger.info "New item notification was sent to: #{bcc}"
    end
  end

  # Sent signed agreement link for a user without CU authentication to sign agreement.
  def request_for_agreement(name, email, token)
    @token = token
    @name = name

    subject = 'Signature request: Columbia Academic Commons participation agreement'
    mail(to: email, subject: subject)
  end

  # Notification sent out to self-identified student depositors. This
  # notification serves as a reminder that departmental approval is required
  # for student works.
  def reminder_to_request_departmental_approval(name, email)
    @name = name

    mail(to: email, subject: 'Request Department Approval')
  end
end
