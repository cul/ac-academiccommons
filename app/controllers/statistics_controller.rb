class StatisticsController < ApplicationController
  layout 'application'
  before_action :require_admin!, except: :unsubscribe_monthly
  include Blacklight::SearchHelper
  include AcademicCommons::Statistics

  require 'csv'

  helper_method :facet_names, :facet_items, :months

  def unsubscribe_monthly
    author_id = params[:author_id].to_s

    begin
      raise 'Request missing parameters.' if author_id.blank? || params[:chk].blank?
      raise 'Cannot be verified.' unless Rails.application.message_verifier(:unsubscribe).verify(params[:chk]) == author_id

      epref = EmailPreference.find_or_initialize_by(author: author_id)
      epref.monthly_opt_out = true
      epref.save!

      flash[:success] = 'Unsubscribe request successful'
    rescue
      flash[:error] = 'There was an error with your unsubscribe request'
    end

    redirect_to root_url
  end

  def all_author_monthlies
    commit_button_all = 'Send To Authors'
    commit_button_all_to_single = 'Send All Reports To Single Email'
    commit_button_aternate = 'Test Alternate Email For Person'
    commit_button_one_to_one = 'Send Report For Single Person'

    params[:email_template] ||= 'Normal'

    ids = repository.search(rows: 100_000, page: 1, fl: 'author_uni_ssim')['response']['docs'].collect { |f| f['author_uni_ssim'] }.flatten.compact.uniq - EmailPreference.where(monthly_opt_out: true).collect(&:author)

    emails = EmailPreference.where('email is NOT NULL and monthly_opt_out = 0').collect

    alternate_emails = Hash.new

    emails.each do |ep|
      alternate_emails[ep.author] = ep.email;
    end

    @authors = ids.collect { |id| {id: id, email: alternate_emails[id] || "#{id}@columbia.edu"}}

    if params[:commit]

      if params[:commit].in?(commit_button_all)
        processed_authors = @authors
        final_notice = 'All monthly reports processing was started.'
      end

      if params[:commit].in?(commit_button_all_to_single)
        if params[:designated_recipient].empty?
          flash.now[:error] = 'Cannot \'Send All Reports To Single Email\' - the destination email was not provided'
          return
        end
        processed_authors = @authors
        final_notice = 'All monthly reports processing was started to be sent to ' + params[:designated_recipient]
        designated_recipient = params[:designated_recipient]
      else
        params[:designated_recipient] = nil
      end

      if params[:commit].in?(commit_button_aternate)
        if params[:test_users].empty?
          flash.now[:error] = 'Could not get statistics. The UNI must be provided!'
          clean_params(params)
          return
        end

        email = alternate_emails[params[:test_users].to_s]
        if email.nil? || email.empty?
          flash.now[:error] = 'Could not get statistics for ' + params[:test_users].to_s + '. The alternate email was not found!'
          clean_params(params)
          return
        end
        processed_authors = make_test_author(params[:test_users].to_s, alternate_emails[params[:test_users].to_s])
        final_notice = 'The monthly report for ' + params[:test_users].to_s + ' was sent to ' + alternate_emails[params[:test_users].to_s]
      end

      if params[:commit].in?(commit_button_one_to_one )

        if params[:one_report_uni].empty? || params[:one_report_email].empty?
          flash.now[:error] = 'Could not get statistics. The UNI and Email must be provided!'
          return
        end
        processed_authors = make_test_author(params[:one_report_uni].to_s, params[:one_report_email])
        final_notice = 'The monthly report for ' + params[:one_report_uni].to_s + ' was sent to ' + params[:one_report_email]
      end

      if(!monthly_reports_in_process?)
        send_authors_reports(processed_authors, designated_recipient)
      else
        final_notice = 'The process is already running.'
      end

      logger.info '============= final_notice: ' + final_notice

      flash.now[:notice] = final_notice

      clean_params(params)
    end
  end

  def detail_report
    set_default_params(params)

    startdate = Date.parse(params[:month_from] + ' ' + params[:year_from])
    enddate = Date.parse(params[:month_to] + ' ' + params[:year_to])
    enddate = Date.new(enddate.year, enddate.month, -1) # needs to be the last day of month

    solr_params = detail_report_solr_params(params[:facet], params[:search_criteria])

    if params[:commit].in?('View', 'Email', 'Get Usage Stats', 'keyword search')
      log_statistics_usage(startdate, enddate, params)
      @usage_stats = AcademicCommons::Metrics::UsageStatistics.new(
        solr_params, startdate, enddate,
        order_by: params[:order_by], include_zeroes: params[:include_zeroes],
        include_streaming: params[:include_streaming_views]
      )

      if @usage_stats.empty?
        if (params[:facet] != 'text')
          @message = 'first_message'
          params[:facet] = 'text'
        else
          @message = 'second_message'
          params[:facet] = 'text'
        end
        return
      end

      if params[:commit] == 'Email'
        Notifier.statistics_by_search(params[:email_destination], params[:search_criteria], @usage_stats, request).deliver
        flash.now[:notice] = 'The report for: ' + params[:search_criteria] + ' was sent to: ' + params[:email_destination]
      end
    end

    if params[:commit] == 'Download CSV report'
       usage_stats = AcademicCommons::Metrics::UsageStatistics.new(
         solr_params, startdate, enddate,
         order_by: params[:order_by], include_zeroes: params[:include_zeroes],
         include_streaming: params[:include_streaming_views],
         recent_first: params[:recent_first], per_month: true
       )
      log_statistics_usage(startdate, enddate, params)
      csv_report = usage_stats.to_csv_by_month(requested_by: current_user)

      if csv_report != nil
        send_data csv_report, type: 'application/csv', filename: params[:search_criteria] + '_monthly_statistics.csv'
      end
    end
  end

  def total_usage_stats
    solr_params = {
      q: params.fetch(:q, nil), # needs to be raw query
      fq: query_to_facets(params.fetch(:f, []))
    }

    s, e = nil, nil
    if params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to]
      s = start_date(params[:month_from], params[:year_from])
      e = end_date(params[:month_to], params[:year_to])
    end

    usage_stats = AcademicCommons::Metrics::UsageStatistics.new(solr_params, s, e, include_streaming: true)

    time = (usage_stats.lifetime_only?) ? 'Lifetime' : 'Period'

    json = { 'records' => usage_stats.count } # Number of records.
    [Statistic::VIEW, Statistic::DOWNLOAD, Statistic::STREAM].each do |event|
      json[event.downcase] = usage_stats.total_for(event, time)
    end

    respond_to do |f|
      f.json { render json: json }
    end
  end

  def common_statistics_csv
    usage_stats = get_res_list

    unless usage_stats.empty?
      csv = usage_stats.to_csv

      send_data csv, type: 'application/csv', filename: 'common_statistics.csv'
    end
  end

  def generic_statistics; end

  def school_statistics; end

  def statistic_res_list
    @usage_stats = get_res_list
  end

  def send_csv_report
    params.each do |key, value|
      logger.info('pram: ' + key + ' = ' + value.to_s)
    end

    recipients = params[:email_to]
    from = params[:email_from]
    subject = params[:email_subject]
    message = params[:email_message]

    prepared_attachments = Hash.new
    csv = get_res_list.to_csv
    prepared_attachments.store('statistics.csv', csv)

    Notifier.statistics_report_with_csv_attachment(recipients, from, subject, message, prepared_attachments).deliver

    render text: 'sent'
  end

  def free_to_read?(doc)
    true # document embargo authorization is not relevant here
  end

  private

  def monthly_reports_in_process?
    Dir.glob("#{Rails.root}/log/monthly_reports/*.tmp") do |log_file_path|
      return true
    end
    return false
  end

  def set_default_params(params)
    if (params[:month_from].nil? || params[:month_to].nil? || params[:year_from].nil? || params[:year_to].nil?)

      params[:month_from] = 'Apr'
      params[:year_from] = '2011'
      params[:month_to] = (Date.current - 1.months).strftime('%b')
      params[:year_to] = (Date.current).strftime('%Y')

      params[:include_zeroes] = true
    end
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
