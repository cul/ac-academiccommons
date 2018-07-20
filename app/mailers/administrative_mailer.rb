class AdministrativeMailer < ApplicationMailer
  # This mailer contains emails that should go to the Academic Commons
  # administrative staff.
  default to: Rails.application.config_for(:emails)['administrative_notifications']

  MAX_FILE_SIZE = 1024 * 1024 * 25 # Max file size (25 MB) that can be emailed in KB.

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
end
