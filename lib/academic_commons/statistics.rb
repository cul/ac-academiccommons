require 'csv'
require 'uri'
module AcademicCommons
  module Statistics
    include AcademicCommons::Listable

    VIEW = 'View '
    DOWNLOAD = 'Download '

    FACET_NAMES = Hash.new
    FACET_NAMES.store('author_facet', 'Author')
    FACET_NAMES.store('pub_date_facet', 'Date')
    FACET_NAMES.store('genre_facet', 'Content Type')
    FACET_NAMES.store('subject_facet', 'Subject')
    FACET_NAMES.store('type_of_resource_facet', 'Resource Type')
    FACET_NAMES.store('media_type_facet', 'Media Type')
    FACET_NAMES.store('organization_facet', 'Organization')
    FACET_NAMES.store('department_facet', 'Department')
    FACET_NAMES.store('series_facet', 'Series')
    FACET_NAMES.store('non_cu_series_facet', 'Non CU Series')

    private

    # Copied from Catalog Helper.
    # TODO: Needs to be in a more centralized place.
    def get_count(query_params)
      Blacklight.default_index.search(query_params)["response"]["numFound"]
    end

    def facet_names
      FACET_NAMES
    end

    # Return array of abbreviated month names.
    def months
      Array.new(Date::ABBR_MONTHNAMES).drop(1)
    end

    def set_message_and_variables
      @results = nil
      @stats = nil
      @totals = nil
      if (params[:facet] != "text")
        @message = "first_message"
        params[:facet] = "text"
      else
        @message = "second_message"
        params[:facet] = "text"
      end
    end

    def log_statistics_usage(startdate, enddate, params)
      eventlog = Eventlog.create(:event_name => 'statistics',
      :user_name  => current_user == nil ? "N/A" : current_user.to_s,
      :uid        => current_user == nil ? "N/A" : current_user.uid.to_s,
      :ip         => request.remote_ip,
      :session_id => request.session_options[:id])

      eventlog.logvalues.create(:param_name => "startdate", :value => startdate.to_s)
      eventlog.logvalues.create(:param_name => "enddate", :value => enddate.to_s)
      eventlog.logvalues.create(:param_name => "commit", :value => params[:commit])
      eventlog.logvalues.create(:param_name => "search_criteria", :value => params[:search_criteria] )
      eventlog.logvalues.create(:param_name => "include_zeroes", :value => params[:include_zeroes] == nil ? "false" : "true")
      eventlog.logvalues.create(:param_name => "include_streaming_views", :value => params[:include_streaming_views] == nil ? "false" : "true")
      eventlog.logvalues.create(:param_name => "facet", :value => params[:facet])
      eventlog.logvalues.create(:param_name => "email_to", :value => params[:email_destination] == "email to" ? nil : params[:email_destination])
    end

    def make_test_author(author_id, email)
      [{ id: author_id, email: email }]
    end

    def school_pids(school)
      Blacklight.default_index.search(
        'qt' => "search", 'rows'=> 20000, 'facet.field'=>["pid"],
        'fq' => ["{!raw f=organization_facet}#{school}"]
      )["response"]["docs"]
    end

    def get_school_docs_size(school)
      query_params = {:qt=>"standard", :q=>'{!raw f=organization_facet}' + school}
      return get_count(query_params)
    end

    def facet_items(facet)
      query_params = {:q => "", :rows => 0, 'facet.limit' => -1, 'facet.field' => [facet]}
      solr_results = Blacklight.default_index.search(query_params)
      subjects = solr_results.facet_counts["facet_fields"][facet]

      results = [["" ,""]]

      res_item = {}
      subjects.each do |item|
        if(item.kind_of? Integer)
          res_item[:count] = item
          results << ["#{res_item[:name]} (#{res_item[:count]})", res_item[:name].to_s]
          res_item = {}
        else
          res_item[:name] = item
        end
      end

      results
    end


    def get_pids_by_query_facets(query)
      facets_query = query.map do |param|
        facet = param[0]
        facet_item = param[1][0].to_s
        (facet_item.blank? || facet_item == 'undefined') ? nil : "{!raw f=#{facet}}#{facet_item}"
      end.compact

      query_params = {
        "qt" => "search", "rows" => 20000, "facet.field" => ["pid"],
        "fq" => facets_query
      }
      Blacklight.default_index.search(query_params)["response"]["docs"]
    end

    def count_pids_statistic(pids_collection, event)
      Statistic.where("identifier in (?) and event = ?", collect_asset_pids(pids_collection, event), event).count
    end

    def count_pids_statistic_by_dates(pids_collection, event, startdate, enddate)
      Statistic.where("identifier in (?) and event = ? and at_time BETWEEN ? and ?", collect_asset_pids(pids_collection, event), event, startdate, enddate).count
    end

    def count_docs_by_event(pids_collection, event)
      Statistic.group(:identifier).where("identifier in (?) and event = ? ", collect_asset_pids(pids_collection, event), event).count
    end

    def count_docs_by_event_and_dates(pids_collection, event, startdate, enddate)
      Statistic.group(:identifier).where("identifier in (?) and event = ? and at_time BETWEEN ? and ? ", collect_asset_pids(pids_collection, event), event, startdate, enddate).count
    end

    # Maps a collection of Item/Aggregator PIDs to File/Asset PIDs
    def collect_asset_pids(pids_collection, event)
      pids_collection.map do |pid|
        pid[:id] ||= pid[:pid] # facet doc may be submitted with only pid value
        if(event == Statistic::DOWNLOAD_EVENT)
          most_downloaded_asset(pid) # Chooses most downloaded over lifetime.
        else
          pid[:id]
        end
      end.flatten.compact.uniq
    end

    # Most downloaded asset over entire lifetime.
    # Eventually may have to reevaluate this for queries that are for a specific
    # time range. For now, we are okay with this assumption.
    def most_downloaded_asset(pid)
      asset_pids = build_resource_list(pid).map { |doc| doc[:pid] }
      return asset_pids.first if asset_pids.count == 1

      # Get the higest value stored here.
      counts = Statistic.event_count(asset_pids, Statistic::DOWNLOAD_EVENT)

      # Return first pid, if items have never been downloaded.
      return asset_pids.first if counts.empty?

      # Get key of most downloaded asset.
      key, value = counts.max_by{ |_,v| v }
      key
    end

    def get_res_list
      query = params[:f]

      return [] if query.blank?

      docs = get_pids_by_query_facets(query)

      results = Array.new

      docs.each do |doc|
        item = Hash.new

        if(params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to] )
          startdate = Date.parse(params[:month_from] + " " + params[:year_from])
          enddate = Date.parse(params[:month_to] + " " + params[:year_to])

          item.store('views', count_pids_statistic_by_dates([doc], Statistic::VIEW_EVENT, startdate, enddate))
          item.store('downloads', count_pids_statistic_by_dates([doc], Statistic::DOWNLOAD_EVENT, startdate, enddate))
          item.store('streams', count_pids_statistic_by_dates([doc], Statistic::STREAM_EVENT, startdate, enddate))
          item.store('doc', doc)

          results << item
        else

          item.store('views', count_pids_statistic([doc], Statistic::VIEW_EVENT))
          item.store('downloads', count_pids_statistic([doc], Statistic::DOWNLOAD_EVENT))
          item.store('streams', count_pids_statistic([doc], Statistic::STREAM_EVENT))
          item.store('doc', doc)
          results << item
        end
      end

      results.sort! do |x,y|
        x['doc']['title_display']<=> y['doc']['title_display']
      end

      return results
    end

    def get_docs_size_by_query_facets
      query = params[:f]

      if query == nil || query.empty?
        []
      else
        get_pids_by_query_facets(query)
      end
    end

    def get_time_period
      if(params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to])
        startdate = Date.parse(params[:month_from] + " " + params[:year_from])
        enddate = Date.parse(params[:month_to] + " " + params[:year_to])
        "#{startdate.strftime("%b %Y")} - #{enddate.strftime("%b %Y")}"
      else
        'Lifetime'
      end
    end

    def create_common_statistics_csv(res_list)
      count = 0
      csv = ''

      csv += CSV.generate_line( [ 'time period: ', get_time_period, '', '', '', '', '', '' ])
      csv += CSV.generate_line( [ '', '', '', '', '', '', '', ''])

      query = params[:f]
      views_stats = get_facet_stats_by_event(query, Statistic::VIEW_EVENT)
      downloads_stats = get_facet_stats_by_event(query, Statistic::DOWNLOAD_EVENT)
      streams_stats = get_facet_stats_by_event(query, Statistic::STREAM_EVENT)

      csv += CSV.generate_line( [ 'FACET', 'ITEM', '', '', '', '', '', ''])
      query.each do |key, value|
        csv += CSV.generate_line( [ facet_names[key.to_s], value.first.to_s, '', '', '', '', '', ''])
      end
      csv += CSV.generate_line( [ '', '', '', '', '', '', '', '' ])

      csv += CSV.generate_line( [ res_list.size.to_s, '', '', views_stats['statistic'].to_s, downloads_stats['statistic'].to_s, streams_stats['statistic'].to_s, '', '' ])
      csv += CSV.generate_line( [ '#', 'TITLE', 'GENRE', 'VIEWS', 'DOWNLOADS', 'STREAMS', 'DEPOSIT DATE', 'HANDLE / DOI' ])

      res_list.each do |item|
        count = count + 1

        csv += CSV.generate_line( [
          count,
          item['doc']['title_display'],
          item['doc']['genre_facet'].first,
          item['views'],
          item['downloads'],
          item['streams'],
          Date.strptime(item['doc']['record_creation_date']).strftime('%m/%d/%Y'),
          item['doc']['handle']
          ])
        end

      return csv
    end

    def get_facet_stats_by_event(query, event)
      if( query == nil || query.empty? )
        downloads = 0
        docs = Hash.new
      else
        pids_collection = get_pids_by_query_facets(query)

        if(params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to] )
          startdate = Date.parse(params[:month_from] + " " + params[:year_from])
          enddate = Date.parse(params[:month_to] + " " + params[:year_to])
          count = count_pids_statistic_by_dates(pids_collection, event, startdate, enddate)
          docs = count_docs_by_event_and_dates(pids_collection, event, startdate, enddate)
        else
          count = count_pids_statistic(pids_collection, event)
          docs = count_docs_by_event(pids_collection, event)
        end
      end

      result = Hash.new
      result.store('docs_size', docs.size.to_s)
      result.store('statistic', count.to_s)
      result
    end

    def send_authors_reports(processed_authors, designated_recipient)
      start_time = Time.new
      time_id = start_time.strftime("%Y%m%d-%H%M%S")
      log_path = File.join(Rails.root, 'log', 'monthly_reports')
      logger = Logger.new(File.join(log_path, "#{time_id}.tmp"))

      logger.info "=== All Authors Monthly Reports ==="
      logger.info "Started at: " + start_time.strftime("%Y-%m-%d %H:%M")

      sent_counter = 0
      skipped_counter = 0
      sent_exceptions = 0

      processed_authors.each do |author|
        begin
          author_id = author[:id]
          startdate = Date.parse(params[:month] + " " + params[:year])
          enddate = Date.new(startdate.year, startdate.month, -1) # end_date needs to be last day of month

          usage_stats = AcademicCommons::UsageStatistics.new(
            startdate, enddate, author_id, 'author_uni', order_by: params[:order_by],
            include_zeroes: params[:include_zeroes], include_streaming: false,
          )

          email = designated_recipient || author[:email]
          raise "no email address found" if email.nil?

          if usage_stats.none?(&:zero?) || params[:include_zeroes]
            sent_counter += 1
            if(params[:do_not_send_email])
              test_msg = ' (this is test - email was not sent)'
            else
              Notifier.author_monthly(email, author_id, usage_stats, params[:optional_note]).deliver
              test_msg = ''
            end

            logger.info "Report for '#{author_id}' was sent to #{email} at " + Time.new.strftime("%Y-%m-%d %H:%M") + test_msg
          else
            skipped_counter += 1
            logger.info "Report for '#{author_id}' was skipped"
          end

        rescue Exception => e
          logger.error "For #{author_id}, email: #{author[:email]}"
          logger.error "#{e}\n\t#{e.backtrace.join("\n\t")}"
          sent_exceptions += 1
        end
      end

      finish_time = Time.new
      logger.info "Number of emails"
      logger.info "\tsent: #{sent_counter}, skipped: #{skipped_counter}, errors: #{sent_exceptions}"
      logger.info "Finished at: " + finish_time.strftime("%Y-%m-%d %H:%M")

      seconds_spent = finish_time - start_time
      readble_time_spent = Time.at(seconds_spent).utc.strftime("%H hours, %M minutes, %S seconds")

      logger.info "Time spent: #{readble_time_spent}"

      File.rename(File.join(log_path, "#{time_id}.tmp"), File.join(log_path, "#{time_id}.log"))
    end

    def clean_params(params)
      params[:one_report_uni] = nil
      params[:test_users] = nil
      params[:designated_recipient] = nil
      params[:one_report_email] = nil
    end
  end
end
