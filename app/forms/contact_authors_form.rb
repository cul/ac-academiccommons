# frozen_string_literal: true

class ContactAuthorsForm < FormObject
  SUBJECT = 'Message from Academic Commons Admin'

  attr_accessor :send_to, :unis, :subject, :body

  validates :send_to, :subject, :body, presence: true
  validates :unis, presence: true, if: proc { |m| m.send_to == 'specific_authors' }
  validate :valid_unis_format?, if: proc { |m| m.send_to == 'specific_authors' }

  def valid_unis_format?
    unis.split(',').each do |uni|
      if uni.empty? || uni.strip =~ /\s/
        errors.add(:unis, 'list must be properly formatted')
        break
      end
    end
  end

  def send_emails
    return false unless valid?

    begin
      # Send in batches of 100
      recipients.each_slice(100) do |recipient_batch|
        UserMailer.contact_authors(recipient_batch, body, subject).deliver_now
      end
    rescue StandardError
      errors.add(:base, 'There was an error sending the email')
      return false
    end

    true
  end

  def recipients
    ids = if send_to == 'specific_authors'
            unis.split(',').map!(&:strip)
          else
            AcademicCommons.all_author_unis
          end

    EmailPreference.preferred_emails(ids).values
  end
end
