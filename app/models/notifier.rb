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
  
  def new_deposit(request, file_download_url)
    @accepted_agreement = (request[:acceptedAgreement] == "agree") ? true : false
    @agreement_version = request["AC-agreement-version"]
    @uni = request[:uni]
    @name = request[:name]
    @email = request[:email]
    @title = request[:title]
    @authors = request[:author]
    @abstract = request[:abstr]
    @url = request[:url]
    @doi_pmcid = request[:doi_pmcid]
    @notes = request[:software]    
    @file_download_url = file_download_url
    recipients NEW_DEPOSIT_RECIPIENTS
    from MAIL_DELIVERER
    subject "New Academic Commons Deposit Request"
    content_type 'text/html'
  end
  
end
