class ContactAuthorsForm < FormObject
  attr_accessor :send_to, :unis, :subject, :body

  validates :send_to, :subject, :body, presence: true
  # TODO : add validation rules

  def send_emails
    Rails.logger.debug('EmailAuthorMessageForm#send_emails: Entry')
    return false unless valid? # Call all validations

    Rails.logger.debug 'EmailAuthorMessageForm#send_emails: sending email...'

    begin
      UserMailer.contact_authors(recipients, body, subject).deliver_now
    rescue StandardError
      errors.add(:base, '(DEV contact authors error) there was an error sending the email') # TODO : remove dev message
      return false
    end

    true
  end

  def recipients
    return ['bg2918@columbia.edu'] # TODO : For now, only ever send email here

    ids = send_to == 'specific' ? unis.split(',') : AcademicCommons.all_author_unis

    EmailPreference.preferred_emails(ids)
  end
end
