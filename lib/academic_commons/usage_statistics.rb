module AcademicCommons
  class UsageStatistics
    include AcademicCommons::Listable
    include AcademicCommons::Statistics::OutputCSV

    attr_reader :start_date, :end_date, :months_list, :facet, :query, :ids
    attr_accessor :stats, :totals, :results, :download_ids, :options

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
      self.options = DEFAULT_OPTIONS.merge(options)
      @months_list = (options[:per_month]) ? make_months_list(options[:recent_first]) : nil
      generate_stats(query, facet)
    end

    def get_stat_for(id, event, time='Period') # time can be Lifetime, Period, month-year
      unless /Lifetime|Period|\w{3} \d{4}/.match(time)
        # Mon year format can only be used if per_month is true
        raise 'time must be Lifetime, Period or Mon Year'
      end

      # Check that id given is in ids.
      unless self.ids.include?(id)
        raise 'id given not part of results'
      end

      key = "#{event} #{time}"
      if self.stats.key?(key)
        self.stats[key][id] || 0
      else
        raise "#{key} not part of stats. Check parameters."
      end
    end

    private

    # Returns statistics for all the items returned by a solr query
    def generate_stats(query, facet)
      Rails.logger.debug "In generate_stats for #{query}"
      return if query.blank?

      self.results = make_solr_request(facet, query)
      Rails.logger.debug "Solr request returned #{self.results.count} results."

      return if self.results.nil?

      process_stats()

      unless options[:include_zeroes]
        self.results.reject! { |r| self.get_stat_for(r['id'], VIEW).zero? && self.get_stat_for(r['id'], DOWNLOAD).zero? }
        @ids = results.collect { |r| r['id'].to_s.strip } # Get all the aggregator pids.
      end

      if options[:order_by] == 'views' || options[:order_by] == 'downloads'
        self.results.sort! do |x,y|
          event = if options[:order_by] == 'downloads'
                    DOWNLOAD
                  elsif options[:order_by] == 'views'
                    VIEW
                  end
          self.get_stat_for(y['id'], event) <=> self.get_stat_for(x['id'], event)
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

    def process_stats
      @ids = results.collect { |r| r['id'].to_s.strip } # Get all the aggregator pids.

      # Get pid of most downloaded file for each resource/item.
      self.download_ids = ids.map { |id| [id, most_downloaded_asset(id)] }.to_h

      self.stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 } }
      self.totals = {}

      self.stats["View #{PERIOD}"] = Statistic.event_count(ids, Statistic::VIEW_EVENT, start_date: start_date, end_date: end_date)
      self.stats["View #{LIFETIME}"] = Statistic.event_count(ids, Statistic::VIEW_EVENT)

      stats_downloads = Statistic.event_count(self.download_ids.values, Statistic::DOWNLOAD_EVENT, start_date: start_date, end_date: end_date)
      self.stats["Download #{PERIOD}"] = map_download_stats_to_aggregator(stats_downloads)

      stats_lifetime_downloads = Statistic.event_count(self.download_ids.values, Statistic::DOWNLOAD_EVENT)
      self.stats["Download #{LIFETIME}"] = map_download_stats_to_aggregator(stats_lifetime_downloads)

      if options[:include_streaming]
        self.stats["Streaming #{PERIOD}"] = Statistic.event_count(ids, Statistic::STREAM_EVENT, start_date: start_date, end_date: end_date)
        self.stats["Streaming #{LIFETIME}"] = Statistic.event_count(ids, Statistic::STREAM_EVENT)
      end

      self.stats.each { |key, value| self.totals[key] = value.values.sum }

      if options[:per_month]
        process_stats_by_month(self.stats, self.totals, ids, self.download_ids)
      end
    end

    # For each month get the number of view and downloads for each id and populate
    # them into stats.
    def process_stats_by_month(stats, totals, ids, download_ids)
      self.months_list.each do |date|
        start = Date.new(date.year, date.month, 1)
        final = Date.new(date.year, date.month, -1)
        month_key = start.strftime(MONTH_KEY)

        self.stats["#{VIEW} #{month_key}"] = Statistic.event_count(ids, Statistic::VIEW_EVENT, start_date: start, end_date: final)

        if options[:include_streaming]
          self.stats["#{STREAMING} #{month_key}"] = Statistic.event_count(ids, Statistic::STREAM_EVENT, start_date: start, end_date: final)
        end

        download_stats = Statistic.event_count(self.download_ids.values, Statistic::DOWNLOAD_EVENT, start_date: start, end_date: final)
        self.stats["#{DOWNLOAD} #{month_key}"] = map_download_stats_to_aggregator(download_stats)
      end
    end

    # Maps download stats from asset pids to aggregator pids.
    def map_download_stats_to_aggregator(download_stats)
      downloads = {}
      self.download_ids.each_pair do |id, asset_id|
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
