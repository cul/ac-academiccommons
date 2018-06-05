# TODO: Mailer should be moved to app/mailers directory.
# TODO: Mailer should be divided into NotifierMailer and StatisticsMailer.
class Notifier < ActionMailer::Base
  MAX_FILE_SIZE = 1024 * 1024 * 25 # Max file size (25 MB) that can be emailed in KB.

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

  def new_deposit(root_url, deposit, attach_file = true)
    @agreement_version = deposit.agreement_version
    @uni = deposit.uni
    @name = deposit.name
    @email = deposit.email
    @title = deposit.title
    @authors = deposit.authors
    @abstract = deposit.abstract
    @url = deposit.url
    @doi_pmcid = deposit.doi_pmcid
    @notes = deposit.notes
    @record_url = root_url + 'admin/deposits/' + deposit.id.to_s

    filepath = File.join(Rails.root, deposit.file_path)
    if attach_file && File.size(filepath) < MAX_FILE_SIZE  # Tries to attach file if under 25MB.
      attachments[File.basename(filepath)] = File.read(filepath)
    end

    @file_download_url = root_url + 'admin/deposits/' + deposit.id.to_s + '/file'
    recipients = Rails.application.config_for(:emails)['mail_deposit_recipients']
    from = Rails.application.config_for(:emails)['mail_deliverer']
    subject = 'SD'
    subject.concat(" #{@uni} -") if @uni
    subject.concat(" #{@title.truncate(50)}")

    mail(to: recipients, from: from, subject: subject)
  end

  def new_author_agreement(request)
    @name = request[:name]
    @email = request[:email]
    @agreement_version = request['AC-agreement-version']
    recipients = Rails.application.config_for(:emails)['new_agreement_notification']
    from = Rails.application.config_for(:emails)['mail_deliverer']
    subject = 'Academic Commons Author Agreement Accepted'
    content_type = 'text/html'

    mail(to: recipients, from: from, subject: subject, content_type: content_type)
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
