class Notifier < ActionMailer::Base

  def author_monthly(to_address, author_id, date, results, stats, totals,request)
    @author_id = author_id
    @stats = stats
    @totals = totals
    @results = results
    @date = date.strftime("%b %Y")
    recipients to_address
    from MAIL_DELIVERER
    subject "Academic Commons Monthly Download Report for #{@date}"
    content_type 'text/html'
    @request = request
  end
  
  def author_monthly_first(to_address, author_id, date, results, stats, totals,request)
    @request = request
    @author_id = author_id
    @stats = stats
    @totals = totals
    @results = results
    @date = date.strftime("%b %Y")
    recipients to_address
    from MAIL_DELIVERER
    subject "Academic Commons Monthly Download Report for #{@date}"
    content_type 'text/html'
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
    recipients NEW_DEPOSIT_RECIPIENTS
    from MAIL_DELIVERER
    subject "New Academic Commons Deposit Request"
    content_type 'text/html'
  end
  
  def new_author_agreement(request)
    @name = request[:name]
    @email = request[:email]
    @agreement_version = request["AC-agreement-version"]
    recipients NEW_DEPOSIT_RECIPIENTS
    from MAIL_DELIVERER
    subject "Academic Commons Author Agreement Accepted"
    content_type 'text/html'
  end
  
end
