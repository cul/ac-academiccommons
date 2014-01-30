class Notifier < ActionMailer::Base
  
  def statistics_by_search(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams)
    statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, nil) 
  end

  def author_monthly(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, optional_note)
    statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, optional_note) 
  end
  
  def author_monthly_first(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams)
    statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, nil)
  end
  
  def statistics_report(to_address, author_id, start_date, end_date, results, stats, totals, request, show_streams, optional_note)
    @request = request
    @author_id = author_id
    @stats = stats
    @totals = totals
    @results = results
    @start_date = start_date.strftime("%b %Y")
    @end_date = end_date.strftime("%b %Y")
    recipients = to_address
    from = Rails.application.config.mail_deliverer
    subject = "Academic Commons Monthly Download Report for #{@start_date} - #{@end_date}"
    content_type = 'text/html'
    @streams = show_streams
    @optional_note = optional_note
    
    mail(:to => recipients, :from => from, :subject => subject, :content_type => content_type) 
    
    logger.debug("Report sent for: " + author_id + " to: " + to_address)
  end  
  
  def new_deposit(root_url, deposit)
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
    @record_url = root_url + "admin/deposits/" + deposit.id.to_s
    @file_download_url = root_url + "admin/deposits/" + deposit.id.to_s + "/file"
    recipients = Rails.application.config.mail_deposit_recipients
    from = Rails.application.config.mail_deliverer
    subject = "New Academic Commons Deposit Request"
    content_type = 'text/html'
    
    mail(:to => recipients, :from => from, :subject => subject, :content_type => content_type) 
  end
  
  def new_author_agreement(request)
    @name = request[:name]
    @email = request[:email]
    @agreement_version = request["AC-agreement-version"]
    recipients = Rails.application.config.mail_deposit_recipients
    from = Rails.application.config.mail_deliverer
    subject = "Academic Commons Author Agreement Accepted"
    content_type = 'text/html'
    
    mail(:to => recipients, :from => from, :subject => subject, :content_type => content_type) 
  end
  
end
