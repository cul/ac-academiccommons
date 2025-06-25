class UserMailer < ApplicationMailer
  # This mailer contains emails that go to Academic Commons users.
  helper :catalog # Needed to correctly render persistent url.
  default from: Rails.application.config_for(:emails)['mail_deliverer']

  def new_item_available(solr_doc, uni, email, name = nil)
    @uni = uni
    @name = name
    @email = email
    @solr_doc = solr_doc

    subject = if @solr_doc.embargoed?
                'Your work is now registered in Academic Commons'
              else
                'Your work is now available in Academic Commons'
              end

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

    mail(to: email, subject: 'Department approval may be needed')
  end

  # Email to authors from AC administrators
  # Called when the admin 'Contact Authors' form is submitted
  def contact_authors(recipients, body, subject)
    Rails.logger.debug 'UserMailer#notify_users: entry'
    @body = body
    @subject = subject

    # For now, send to multiple users via BCC field.
    mail(bcc: recipients, subject: subject)
    # this will render app/views/user_mailer/contact_authors.html.erb
  end
end
