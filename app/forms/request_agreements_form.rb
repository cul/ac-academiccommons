class RequestAgreementsForm < FormObject
  attr_accessor :name, :email, :uni

  validates_presence_of :name, :email
  validate :agreement_creds_unique

  # Validates that there isn't an entry already for this email,
  # agreement_version, and uni (if available).
  def agreement_creds_unique
    matching = Agreement.where(
      'lower(email) = ? AND agreement_version = ?', # and have to match version
      email.downcase,
      Agreement::LATEST_AGREEMENT_VERSION
    )

    # Further limit results if a uni is provided.
    matching = matching.where('lower(uni) = ?', uni.downcase) if uni.present?

    errors.add(:base, 'A person with this email (and uni) has already signed an agreement.') unless matching.count.zero?
  end

  def save_and_send_notification
    return false unless valid?

    begin
      token = Rails.application.message_verifier(:agreement).generate([email, uni, Agreement::LATEST_AGREEMENT_VERSION])
      UserMailer.request_for_agreement(name, email, token).deliver_now
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPUnknownError,
           Timeout::Error, Net::SMTPFatalError, IOError, Net::SMTPSyntaxError => e
      Rails.logger.error "Error Sending Email: #{e.message}"
      Rails.logger.error e.backtrace.join("\n ")
      errors.add(:base, 'There was a error sending email notification.')
      return false
    end

    true
  end
end
