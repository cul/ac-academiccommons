class ContactAuthorsForm < FormObject
  SUBJECT = 'Message from Academic Commons Admin'.freeze

  attr_accessor :send_to, :unis, :subject, :body

  validates :send_to, :subject, :body, presence: true
  validates :unis, presence: true, if: proc { |m| m.send_to == 'specific_authors' }
  validate :valid_unis_format?

  def valid_unis_format?
    unis.split(',').each do |uni|
       if uni.empty? || uni.strip =~ /\s/
         errors.add(:unis, 'list must be properly formatted')
         break
       end
    end
  end

  def send_emails
    return false unless valid? # Call all validations

    Rails.logger.debug 'EmailAuthorMessageForm#send_emails: sending email...'

    begin
      UserMailer.contact_authors(recipients, body, subject).deliver_now
    rescue StandardError
      errors.add(:base, 'There was an error sending the email')
      return false
    end

    true
  end

  def recipients
    Rails.logger.debug "ContactAuthorsForm#recipients: Sending emails to #{send_to}"

    if send_to == 'specific_authors'
      ids = unis.split(',').map! { |uni| uni.strip }
    else
      ids = AcademicCommons.all_author_unis
    end

    EmailPreference.preferred_emails(ids).values
  end
end
