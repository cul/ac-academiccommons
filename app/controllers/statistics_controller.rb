class StatisticsController < ApplicationController
  include Blacklight::SearchHelper
  include AcademicCommons::Statistics

  authorize_resource except: :unsubscribe_monthly
  layout 'admin'

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

    render plain: 'sent'
  end

  def free_to_read?(doc)
    true # document embargo authorization is not relevant here
  end

  private

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
