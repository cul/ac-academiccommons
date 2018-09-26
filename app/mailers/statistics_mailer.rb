class StatisticsMailer < ApplicationMailer
  default from: Rails.application.config_for(:emails)['mail_deliverer']

  def author_monthly(to_address, author_id, usage_stats, optional_note)
    @author_id = author_id
    @usage_stats = usage_stats
    recipients = to_address
    from = Rails.application.config_for(:emails)['mail_deliverer']
    full_from = "\"Academic Commons\" <#{from}>"

    subject = "Academic Commons Monthly Download Report for #{@usage_stats.time_period}"
    @streams = @usage_stats.include_streaming
    @optional_note = optional_note

    mail(to: recipients, from: full_from, subject: subject)

    logger.debug("Report sent for: #{author_id} to: #{to_address}")
  end

  # rubocop:disable Metrics/ParameterLists
  def usage_statistics(to, subject, body, csv, usage_stats, stats_display)
    @body = body
    @usage_stats = usage_stats
    @stats_display = stats_display

    attachments['academic_commons_statistics.csv'] = { mimetype: 'text/csv', content: csv } unless csv.nil?

    mail(to: to, subject: subject)
  end
  # rubocop:enable Metrics/ParameterLists
end
