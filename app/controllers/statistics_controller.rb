require 'ac_statistics'

class StatisticsController < ApplicationController
  layout "application"
  before_filter :require_user
  before_filter :require_admin, :except => :unsubscribe_monthly
  include Blacklight::SearchHelper
  include ACStatistics

  require "csv"

  helper_method :facet_names, :facet_items, :base_url, :get_res_list, :get_docs_size_by_query_facets,
                :get_time_period, :months

  def unsubscribe_monthly
    author_id = params[:author_id]

    if author_id && author_id.to_s.crypt("xZ") == params[:chk]
      epref = EmailPreference.find_by_author(author_id)
      if epref
        epref.update_attributes(:monthly_opt_out => true)
      else
        EmailPreference.create!(:author => author_id, :monthly_opt_out => true)
      end
    else
      error=true
    end

    if error
      flash[:error] = "There was an error with your unsubscribe request"
    else
      flash[:notice] = "Unsubscribe request successful"
    end

    redirect_to root_url
  end

  def all_author_monthlies

    commit_button_all = "Send To Authors"
    commit_button_all_to_single = "Send All Reports To Single Email"
    commit_button_aternate = "Test Alternate Email For Person"
    commit_button_one_to_one = "Send Report For Single Person"

    params[:email_template] ||= "Normal"

    ids = repository.search(:per_page => 100000, :page => 1, :fl => "author_uni")["response"]["docs"].collect { |f| f["author_uni"] }.flatten.compact.uniq - EmailPreference.where(monthly_opt_out: true).collect(&:author)

    emails = EmailPreference.where("email is NOT NULL and monthly_opt_out = 0").collect

    alternate_emails = Hash.new

    emails.each do |ep|
      alternate_emails[ep.author] = ep.email;
    end

    @authors = ids.collect { |id| {:id => id, :email => alternate_emails[id] || "#{id}@columbia.edu"}}

    if params[:commit]

      if params[:commit].in?(commit_button_all)
        processed_authors = @authors
        final_notice = "All monthly reports processing was started."
      end

      if params[:commit].in?(commit_button_all_to_single)
        if params[:designated_recipient].empty?
          flash[:notice] = "Can not 'Send All Reports To Single Email' - the destination email was not provided"
          return
        end
        processed_authors = @authors
        final_notice = "All monthly reports processing was started to be sent to " + params[:designated_recipient]
        designated_recipient = params[:designated_recipient]
      else
        params[:designated_recipient] = nil
      end

      if params[:commit].in?(commit_button_aternate)
        if params[:test_users].empty?
          flash[:notice] = "Could not get statistics. The UNI must be provided!"
          clean_params(params)
          return
        end

        email = alternate_emails[params[:test_users].to_s]
        if email.nil? || email.empty?
          flash[:notice] = "Could not get statistics for " + params[:test_users].to_s + ". The alternate email was not found!"
          clean_params(params)
          return
        end
        processed_authors = makeTestAuthor(params[:test_users].to_s, alternate_emails[params[:test_users].to_s])
        final_notice = "The monthly report for " + params[:test_users].to_s + " was sent to " + alternate_emails[params[:test_users].to_s]
      end

      if params[:commit].in?(commit_button_one_to_one )

        if params[:one_report_uni].empty? || params[:one_report_email].empty?
          flash[:notice] = "Could not get statistics. The UNI and Email must be provided!"
          return
        end
        processed_authors = makeTestAuthor(params[:one_report_uni].to_s, params[:one_report_email])
        final_notice = "The monthly report for " + params[:one_report_uni].to_s + " was sent to " + params[:one_report_email]
      end

      if(!isMonthlyReportsInProcess)
        sendAuthorsReports(processed_authors, designated_recipient)
      else
        final_notice = "The process is already running."
      end

      logger.info "============= final_notice: " + final_notice

      flash[:notice] = final_notice

      clean_params(params)

    end # params[:commit].in?("Send")

  end # ========== all_author_monthlies ===================== #

 def detail_report

      setDefaultParams(params)

      startdate = Date.parse(params[:month_from] + " " + params[:year_from])
      enddate = Date.parse(params[:month_to] + " " + params[:year_to])

      if params[:commit].in?('View', "Email", "Get Usage Stats", "keyword search")

        logStatisticsUsage(startdate, enddate, params)
        @results, @stats, @totals =  get_author_stats(startdate,
                                                      enddate,
                                                      params[:search_criteria],
                                                      nil,
                                                      params[:include_zeroes],
                                                      params[:facet],
                                                      params[:include_streaming_views],
                                                      params[:order_by]
                                                      )
        if (@results == nil || @results.size == 0)
          setMessageAndVariables
          return
        end

        if params[:commit] == "Email"
          Notifier.statistics_by_search(params[:email_destination], params[:search_criteria], startdate, enddate, @results, @stats, @totals, request, params[:include_streaming_views]).deliver
          flash[:notice] = "The report for: " + params[:search_criteria] + " was sent to: " + params[:email_destination]
        end
      end

      if params[:commit] == "Download CSV report"
        downloadCSVreport(startdate, enddate, params)
      end
  end

  def school_docs_size()

    schools = params[:school]

    schools_arr = schools.split(',')

    count = 0
    schools_arr.each do |school|
      count = count + get_school_docs_size(school)
    end

    respond_to do |format|
      format.html { render :text => count.to_s }
    end
  end


  def stats_by_event()
    event = params[:event]
    count = Statistic.where(event: event).count

    respond_to do |format|
      format.html { render :text => count.to_s }
    end
  end


  def docs_size_by_query_facets

    respond_to do |format|
      format.html { render :text => get_docs_size_by_query_facets().size.to_s}
    end
  end


  def facetStatsByEvent

    query = params[:f]
    event = params[:event]

    stuts_result = get_facetStatsByEvent(query, event)

    result = stuts_result['docs_size'].to_s + ' ( ' + stuts_result['statistic'].to_s + ' )'

    respond_to do |format|
      format.html { render :text => result.to_s }
    end
  end


  def single_pid_count
    query_params = {:qt=>"standard", :q=>"pid:\"" + params[:pid] + "\""}
    results = repository.search(query_params)
    count = results["response"]["numFound"]

    respond_to do |format|
      format.html { render :text => count.to_s }
    end
  end


  def single_pid_stats
    event = params[:event]
    pid = params[:pid]

    pid_item = Hash.new
    pid_item.store("id", pid)

    pids_collection = Array.new
    pids_collection << Mash.new(pid_item)

    count = countPidsStatistic(pids_collection, event)

    respond_to do |format|
      format.html { render :text => count.to_s }
    end
  end

  def school_stats()
    school = params[:school]
    event = params[:event]

    pids_by_institution = school_pids(school)

    count = countPidsStatistic(pids_by_institution, event)

    respond_to do |format|
      format.html { render :text => count.to_s }
    end
  end

  def common_statistics_csv

    res_list = get_res_list

    if(res_list.size != 0)

      csv = create_common_statistics_csv(res_list)

      send_data csv, :type=>"application/csv", :filename => "common_statistics.csv"
    end


  end

  def generic_statistics

  end

  def school_statistics

  end

  def send_csv_report

    params.each do |key, value|
        logger.info("pram: " + key + " = " + value.to_s)
    end

    recipients = params[:email_to]
    from = params[:email_from]
    subject = params[:email_subject]
    message = params[:email_message]

    prepared_attachments = Hash.new
    csv = create_common_statistics_csv(get_res_list)
    prepared_attachments.store('statistics.csv', csv)

    Notifier.statistics_report_with_csv_attachment(recipients, from, subject, message, prepared_attachments).deliver

    #render nothing: true
    render :text => 'sent'

  end

  private

  def setDefaultParams(params)
     if (params[:month_from].nil? || params[:month_to].nil? || params[:year_from].nil? || params[:year_to].nil?)

      params[:month_from] = "Apr"
      params[:year_from] = "2011"
      params[:month_to] = (Date.today - 1.months).strftime("%b")
      params[:year_to] = (Date.today).strftime("%Y")

      params[:include_zeroes] = true
    end
  end

  def get_monthly_author_stats(options = {})
  startdate = options[:startdate]
    author_id = options[:author_id]
    enddate = startdate + 1.month

    results = repository.search(:per_page => 100000, :sort => "title_display asc" , :fq => "author_uni:#{author_id}", :fl => "title_display,id", :page => 1)["response"]["docs"]
    ids = results.collect { |r| r['id'].to_s.strip }
    download_ids = Hash.new { |h,k| h[k] = [] }
    ids.each do |doc_id|
      download_ids[doc_id] |= ActiveFedora::Base.find(doc_id).list_members.collect(&:pid)
    end
    stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 }}
    totals = Hash.new { |h,k| h[k] = 0 }


    stats['View'] = Statistic.group(:identifier).where("event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", ids, startdate, enddate).count

    stats_downloads = Statistic.group(:identifier).where("event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", download_ids.values.flatten,startdate, enddate).count
    download_ids.each_pair do |doc_id, downloads|

      stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
    end


    stats['View Lifetime'] = Statistic.group(:identifier).where("event = 'View' and identifier IN (?)", ids).count


    stats_lifetime_downloads = Statistic.group(:identifier).where("event = 'Download' and identifier IN (?)" , download_ids.values.flatten).count
    download_ids.each_pair do |doc_id, downloads|

      stats['Download Lifetime'][doc_id] = downloads.collect { |download_id| stats_lifetime_downloads[download_id] || 0 }.sum
    end
    stats.keys.each { |key| totals[key] = stats[key].values.sum }


stats['View'] = convertOrderedHash(stats['View'])
stats['View Lifetime'] = convertOrderedHash(stats['View Lifetime'])

    results.reject! { |r| (stats['View'][r['id'][0]] || 0) == 0 &&  (stats['Download'][r['id']] || 0) == 0 } unless params[:include_zeroes]
    results.sort! do |x,y|
      result = (stats['Download'][y['id']] || 0) <=> (stats['Download'][x['id']] || 0)
      result = x["title_display"] <=> y["title_display"] if result == 0
      result
    end

    return results, stats, totals

  end

def convertOrderedHash(ohash)
  a =  ohash.to_a
  oh = {}
  a.each{|x|  oh[x[0]] = x[1]}
  return oh
end


  ##################
  # Config-lookup methods. Should be moved to a module of some kind, once
  # all this stuff is modulized. But methods to look up config'ed values,
  # so logic for lookup is centralized in case storage methods changes.
  # Such methods need to be available from controller and helper sometimes,
  # so they go in controller with helper_method added.
  # TODO: Move to a module, and make them look inside the controller
  # for info instead of in global Blacklight.config object!
  ###################

  # Look up configged facet limit for given facet_field. If no
  # limit is configged, may drop down to default limit (nil key)
  # otherwise, returns nil for no limit config'ed.
  def facet_limit_for(facet_field)
    limits_hash = facet_limit_hash
    return nil unless limits_hash

    limit = limits_hash[facet_field]
    limit = limits_hash[nil] unless limit

    return limit
  end
  helper_method :facet_limit_for
  # Returns complete hash of key=facet_field, value=limit.
  # Used by SolrHelper#solr_search_params to add limits to solr
  # request for all configured facet limits.
  def facet_limit_hash
    Blacklight.config[:facet][:limits]
  end
  helper_method :facet_limit_hash
end
