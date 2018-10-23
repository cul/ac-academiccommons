class UsageStatisticsReportsEmailForm < UsageStatisticsReportsForm
  attr_accessor :to, :subject, :body, :csv

  validates :to, :subject, :body, :csv, presence: true

  def send_email
    return false unless valid?

    generate_statistics

    csv_data = csv == 'yes' ? to_csv : nil

    begin
      StatisticsMailer.usage_statistics(to, subject, body, csv_data, usage_stats, stat_key).deliver
    rescue StandardError
      errors.add(:base, 'there was an error sending the email')
      return false
    end

    true
  end
end
