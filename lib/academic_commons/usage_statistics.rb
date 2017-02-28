module AcademicCommons
  class UsageStatistics
    include Enumerable
    include AcademicCommons::Listable
    include AcademicCommons::Statistics::OutputCSV

    attr_reader :start_date, :end_date, :months_list, :facet, :query,
                :options, :item_stats

    DEFAULT_OPTIONS = {
      include_zeroes: true, include_streaming: false, per_month: false,
      recent_first: false, order_by: 'title'
    }
    VIEW = 'View'
    DOWNLOAD = 'Download'
    STREAMING = 'Streaming'

    PERIOD = 'Period'
    LIFETIME = 'Lifetime'
    MONTH_KEY = '%b %Y'

    # Create statistics object that calculates usage statistics (views,
    # downloads, and streams) for all the items that match the query. If a time
    # period is given, stats for that time period are calculated. If :per_month
    # is true statistics are broken down by month. Lifetime statistics are always
    # calculated.
    #
    # @param [Date] start_date
    # @param [Date] end_date
    # @param [String] query solr query
    # @param [String] facet
    # @param [Hash] options options to use when creating/rendering stats
    # @option options [Boolean] :include_zeroes flag to indicate whether records with no usage stats should be included
    # @option options [Boolean] :include_streaming
    # @option options [Boolean] :per_month flag to organize/calculate statistics by month
    # @option options [Boolean] :recent_first if true, when listing months list most recent month first
    # @option options [String] :order_by most number of downloads or views
    def initialize(start_date, end_date, query, facet, options = {})
      @start_date = start_date
      @end_date = end_date
      @query = query
      @facet = facet
      @options = DEFAULT_OPTIONS.merge(options)
      @totals = { Statistic::VIEW_EVENT => {}, Statistic::DOWNLOAD_EVENT => {}, Statistic::STREAM_EVENT => {} }
      generate_stats(query, facet)
    end

    def get_stat_for(id, event, time='Period') # time can be Lifetime, Period, month-year
      item = @item_stats.find { |i| i.id == id }
      raise "Could not find #{id}" unless item

      item.get_stat(event, time)
    end

    def each(&block)
      @item_stats.each(&block)
    end

    def total_for(event, time)
      return @totals[event][time] if @totals[event].key?(time)
      @totals[event][time] = @item_stats.reduce(0) { |sum, i| sum + i.get_stat(event, time) }
    end

    def empty?
      @item_stats.count.zero?
    end

    private

    # Returns statistics for all the items returned by the given solr query.
    def generate_stats(query, facet)
      Rails.logger.debug "In generate_stats for #{query}"
      return if query.blank?

      results = make_solr_request(facet, query)
      Rails.logger.debug "Solr request returned #{results.count} results."
      @item_stats = results.map{ |doc| AcademicCommons::Statistics::ItemStats.new(doc) }

      return if @item_stats.count.zero?

      process_stats()

      unless options[:include_zeroes]
        @item_stats.reject! { |i| i.get_stat(VIEW, PERIOD).zero? && i.get_stat(DOWNLOAD, PERIOD).zero? }
      end

      if options[:order_by] == 'views' || options[:order_by] == 'downloads'
        @item_stats.sort! do |x,y|
          event = if options[:order_by] == 'downloads'
                    DOWNLOAD
                  elsif options[:order_by] == 'views'
                    VIEW
                  end
          y.get_stat(event, PERIOD) <=> x.get_stat(event, PERIOD)
          # sort_by title
        end
      end
    end

    # Creates list of month-year strings in order from the startdate to the
    # enddate given.
    #
    # @param recent_first flag that reverses array
    def make_months_list(recent_first = false)
      months = []
      date = self.start_date
      while date <= self.end_date
        months << date
        date += 1.month
      end

      (recent_first) ? months.reverse : months
    end

    def add_item_stats(event, time, stats)
      @item_stats.each do |i|
        value = stats.key?(i.id) ? stats[i.id] : 0
        i.add_stat(event, time, value)
      end
    end



    def process_stats
      ids = @item_stats.collect(&:id) # Get all the aggregator pids.

      # Get pid of most downloaded file for each resource/item.
      download_ids_map = ids.map { |id| [id, most_downloaded_asset(id)] }.to_h

      view_period = Statistic.event_count(ids, Statistic::VIEW_EVENT, start_date: start_date, end_date: end_date)
      add_item_stats(Statistic::VIEW_EVENT, PERIOD, view_period)

      add_item_stats(Statistic::VIEW_EVENT, LIFETIME, Statistic.event_count(ids, Statistic::VIEW_EVENT))

      period_downloads = Statistic.event_count(download_ids_map.values, Statistic::DOWNLOAD_EVENT, start_date: start_date, end_date: end_date)
      period_downloads = map_download_stats_to_aggregator(period_downloads, download_ids_map)
      add_item_stats(Statistic::DOWNLOAD_EVENT, PERIOD, period_downloads)

      lifetime_downloads = Statistic.event_count(download_ids_map.values, Statistic::DOWNLOAD_EVENT)
      lifetime_downloads = map_download_stats_to_aggregator(lifetime_downloads, download_ids_map)
      add_item_stats(Statistic::DOWNLOAD_EVENT, LIFETIME, lifetime_downloads)

      if options[:include_streaming]
        period_streams = Statistic.event_count(ids, Statistic::STREAM_EVENT, start_date: start_date, end_date: end_date)
        add_item_stats(Statistic::STREAM_EVENT, PERIOD, period_streams)

        add_item_stats(Statistic::STREAM_EVENT, LIFETIME, Statistic.event_count(ids, Statistic::STREAM_EVENT))
        total_for(Statistic::STREAM_EVENT, PERIOD)
        total_for(Statistic::STREAM_EVENT, LIFETIME)
      end

      if options[:per_month]
        @months_list = make_months_list(options[:recent_first])
        process_stats_by_month(ids, download_ids_map)
      end
    end

    # For each month get the number of view and downloads for each id and populate
    # them into stats.
    def process_stats_by_month(ids, download_ids_map)
      self.months_list.each do |date|
        start = Date.new(date.year, date.month, 1)
        final = Date.new(date.year, date.month, -1)
        month_key = start.strftime(AcademicCommons::Statistics::ItemStats::MONTH_KEY)

        # @stats["#{VIEW} #{month_key}"] = Statistic.event_count(ids, Statistic::VIEW_EVENT, start_date: start, end_date: final)
        views = Statistic.event_count(ids, Statistic::VIEW_EVENT, start_date: start, end_date: final)
        add_item_stats(Statistic::VIEW_EVENT, month_key, views)

        if options[:include_streaming]
          streams = Statistic.event_count(ids, Statistic::STREAM_EVENT, start_date: start, end_date: final)
          add_item_stats(Statistic::STREAM_EVENT, month_key, streams)
        end

        download_stats = Statistic.event_count(download_ids_map.values, Statistic::DOWNLOAD_EVENT, start_date: start, end_date: final)
        download_stats = map_download_stats_to_aggregator(download_stats, download_ids_map)
        add_item_stats(Statistic::DOWNLOAD_EVENT, month_key, download_stats)
      end
    end

    # Maps download stats from asset pids to aggregator pids.
    def map_download_stats_to_aggregator(download_stats, download_ids_map)
      downloads = {}
      download_ids_map.each_pair do |id, asset_id|
        if num = download_stats[asset_id]
          downloads[id] = num
        end
      end
      downloads
    end

    def parse_search_query(search_query)
      search_query = URI.unescape(search_query)
      search_query = search_query.gsub(/\+/, ' ')

      params = Hash.new

      if search_query.include? '?'
        search_query = search_query[search_query.index("?") + 1, search_query.length]
      end

      search_query.split('&').each do |value|
        key_value = value.split('=')

        if(key_value[0].start_with?("f[") )
          if(params.has_key?("f"))
            array = params["f"]
          else
            array = Array.new
          end

          value = key_value[0].gsub(/f\[/, '').gsub(/\]\[\]/, '') + ":\"" + key_value[1] + "\""
          array.push(value)
          params.store("f", array)
        else
          params.store(key_value[0], key_value[1])
        end
      end

      return params
    end

    def make_solr_request(facet, query)
      Rails.logger.debug "In make_solr_request for query: #{query}"
      if facet == "search_query"
        solr_params = parse_search_query(query)
        facet_query = solr_params["f"]
        q = solr_params["q"]
        sort = solr_params["sort"]
      else
        facet_query = "#{facet}:\"#{query}\""
        sort = "title_display asc"
      end

      return if facet_query.nil? && q.nil?

      Blacklight.default_index.search(
        :rows => 100000, :sort => sort, :q => q, :fq => facet_query,
        :fl => "title_display,id,handle,doi,genre_facet", :page => 1
      )["response"]["docs"]
    end

    # Most downloaded asset over entire lifetime.
    # Eventually may have to reevaluate this for queries that are for a specific
    # time range. For now, we are okay with this assumption.
    def most_downloaded_asset(pid)
      asset_pids = build_resource_list({ 'id' => pid }).map { |doc| doc[:pid] }
      return asset_pids.first if asset_pids.count == 1

      # Get the higest value stored here.
      counts = Statistic.event_count(asset_pids, Statistic::DOWNLOAD_EVENT)

      # Return first pid, if items have never been downloaded.
      return asset_pids.first if counts.empty?

      # Get key of most downloaded asset.
      key, value = counts.max_by{ |_,v| v }
      key
    end

    def free_to_read?(document) # free_to_read not relevant here
      true
    end
  end
end
