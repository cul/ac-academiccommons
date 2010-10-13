class Notifier < ActionMailer::Base
  

  def author_monthly(to_address, author_id, date, results, stats, totals)
    @author_id = author_id
    @stats = stats
    @totals = totals
    @results = results
    @date = date.strftime("%b %Y")
    recipients to_address
    from "academic.commons@columbia.edu"
    subject "Academic Commons Monthly Download Report for #{@date}"
    content_type 'text/html'

  end
end
