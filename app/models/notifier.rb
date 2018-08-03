# TODO: Mailer should be moved to app/mailers directory.
# TODO: Mailer should be divided into NotifierMailer and StatisticsMailer.
class Notifier < ActionMailer::Base
  def statistics_by_search(to_address, author_id, usage_stats, request)
    statistics_report(to_address, author_id, usage_stats, request, nil)
  end

  def author_monthly(to_address, author_id, usage_stats, optional_note)
    statistics_report(to_address, author_id, usage_stats, '', optional_note)
  end

  def statistics_report(to_address, author_id, usage_stats, request, optional_note)
    @request = request
    @author_id = author_id
    @usage_stats = usage_stats
    recipients = to_address
    from = Rails.application.config_for(:emails)['mail_deliverer']
    full_from = "\"Academic Commons\" <#{from}>"

    subject = "Academic Commons Monthly Download Report for #{@usage_stats.time_period}"
    @streams = @usage_stats.options[:include_streaming]
    @optional_note = optional_note

    mail(to: recipients, from: full_from, subject: subject)

    logger.debug("Report sent for: #{author_id} to: #{to_address}")
  end

  def statistics_report_with_csv_attachment(recipients, from, subject, message, prepared_attachments)

   prepared_attachments.each do |file_name, content|
    attachments.inline[file_name] = {mime_type: 'text/csv', content: content }
   end

    mail(to: recipients, from: from, subject: subject) do |f|
      f.text { render plain: message }
    end
  end
end
