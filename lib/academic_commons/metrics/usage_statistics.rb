module AcademicCommons::Metrics
  class UsageStatistics
    include Enumerable
    include AcademicCommons::Embargoes
    include AcademicCommons::Listable
    include AcademicCommons::Metrics::OutputCSV

    attr_reader :start_date, :end_date, :months_list, :solr_params,
                :options, :item_stats

    DEFAULT_OPTIONS = {
      include_zeroes: true, include_streaming: false, per_month: false,
      recent_first: false, order_by: nil
    }

    DEFAULT_SOLR_PARAMS = {
      rows: 100_000, page: 1,
      fl: 'title_display,id,handle,doi,genre_facet,record_creation_date,object_state_ssi,free_to_read_start_date'
    }

    PERIOD = 'Period'
    LIFETIME = 'Lifetime'
    MONTH_KEY = '%b %Y'

    # Create statistics object that calculates usage statistics (views,
    # downloads, and streams) for all the items that match the solr query. If a
    # time period is given, stats for that time period are calculated. If :per_month
    # is true statistics are broken down by month. Monthly breakdown of stats
    # requires a start and end date. Lifetime statistics are always
    # calculated.
    #
    # @param [Hash] solr_params parameters to conduct solr query with
    # @param [Date] start_date
    # @param [Date] end_date
    # @param [Hash] options options to use when creating/rendering stats
    # @option options [Boolean] :include_zeroes flag to indicate whether records with no usage stats should be included
    # @option options [Boolean] :include_streaming flag to indicate whether streaming statistics should be calculated
    # @option options [Boolean] :per_month flag to organize/calculate statistics by month
    # @option options [Boolean] :recent_first if true, when listing months list most recent month first
    # @option options [String] :order_by most number of downloads or views
    def initialize(solr_params, start_date = nil, end_date = nil, **options)
      @start_date = start_date
      @end_date = end_date
      @solr_params = solr_params
      @options = DEFAULT_OPTIONS.merge(options)
      @totals = { Statistic::VIEW => {}, Statistic::DOWNLOAD => {}, Statistic::STREAM => {} }
      generate_stats
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

    # @return [String] time_period
    def time_period
      if lifetime_only?
        LIFETIME
      else
        [start_date.strftime('%b %Y'), end_date.strftime('%b %Y')].uniq.join(' - ')
      end
    end

    def lifetime_only?
      start_date.blank? && end_date.blank?
    end

    private

    # Returns statistics for all the items returned by the given solr query.
    def generate_stats
      Rails.logger.debug "In generate_stats for #{solr_params.inspect}"
      return if solr_params.blank?

      results = get_solr_documents(solr_params)
      Rails.logger.debug "Solr request returned #{results.count} results."

      # Filtering out embargoed material
      results.reject! { |doc| !free_to_read?(doc) }
      @item_stats = results.map{ |doc| AcademicCommons::Metrics::ItemStats.new(doc) }

      return if @item_stats.empty?

      process_stats

      unless options[:include_zeroes]
        @item_stats.reject! { |i| i.get_stat(Statistic::VIEW, PERIOD).zero? && i.get_stat(Statistic::DOWNLOAD, PERIOD).zero? }
      end

      if options[:order_by] == 'views' || options[:order_by] == 'downloads'
        @item_stats.sort! do |x,y|
          event = if options[:order_by] == 'downloads'
                    Statistic::DOWNLOAD
                  elsif options[:order_by] == 'views'
                    Statistic::VIEW
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
      # Get all the aggregator pids.
      ids = @item_stats.collect(&:id)

      # Get pid of most downloaded file for each resource/item.
      download_ids_map = @item_stats.map { |item| [item.id, most_downloaded_asset(item.document)] }.to_h

      # lifetime
      add_item_stats(Statistic::VIEW, LIFETIME, Statistic.event_count(ids, Statistic::VIEW))

      lifetime_downloads = Statistic.event_count(download_ids_map.values, Statistic::DOWNLOAD)
      lifetime_downloads = map_download_stats_to_aggregator(lifetime_downloads, download_ids_map)
      add_item_stats(Statistic::DOWNLOAD, LIFETIME, lifetime_downloads)

      add_item_stats(Statistic::STREAM, LIFETIME, Statistic.event_count(ids, Statistic::STREAM)) if options[:include_streaming]

      # Period (if start and end date provided)
      unless lifetime_only?
        view_period = Statistic.event_count(ids, Statistic::VIEW, start_date: start_date, end_date: end_date)
        add_item_stats(Statistic::VIEW, PERIOD, view_period)

        period_downloads = Statistic.event_count(download_ids_map.values, Statistic::DOWNLOAD, start_date: start_date, end_date: end_date)
        period_downloads = map_download_stats_to_aggregator(period_downloads, download_ids_map)
        add_item_stats(Statistic::DOWNLOAD, PERIOD, period_downloads)

        if options[:include_streaming]
          period_streams = Statistic.event_count(ids, Statistic::STREAM, start_date: start_date, end_date: end_date)
          add_item_stats(Statistic::STREAM, PERIOD, period_streams)
        end
      end

      # Monthly stats (if flag true)
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
        month_key = start.strftime(AcademicCommons::Metrics::ItemStats::MONTH_KEY)

        views = Statistic.event_count(ids, Statistic::VIEW, start_date: start, end_date: final)
        add_item_stats(Statistic::VIEW, month_key, views)

        if options[:include_streaming]
          streams = Statistic.event_count(ids, Statistic::STREAM, start_date: start, end_date: final)
          add_item_stats(Statistic::STREAM, month_key, streams)
        end

        download_stats = Statistic.event_count(download_ids_map.values, Statistic::DOWNLOAD, start_date: start, end_date: final)
        download_stats = map_download_stats_to_aggregator(download_stats, download_ids_map)
        add_item_stats(Statistic::DOWNLOAD, month_key, download_stats)
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

    def get_solr_documents(params)
      params = params.merge(DEFAULT_SOLR_PARAMS)
      params[:sort] = 'title_display asc' if(params[:sort].blank? || options[:order_by] == 'title')
      params[:fq] = params.fetch(:fq, []).clone << "has_model_ssim:\"#{ContentAggregator.to_class_uri}\""
      # Add filter to remove embargoed items, free_to_read date must be equal to or less than Date.current
      Blacklight.default_index.search(params)['response']['docs']
    end

    # Most downloaded asset over entire lifetime.
    # Eventually may have to reevaluate this for queries that are for a specific
    # time range. For now, we are okay with this assumption.
    def most_downloaded_asset(doc)
      asset_pids = build_resource_list(doc).map { |doc| doc[:pid] }
      return asset_pids.first if asset_pids.count == 1

      # Get the higest value stored here.
      counts = Statistic.event_count(asset_pids, Statistic::DOWNLOAD)

      # Return first pid, if items have never been downloaded.
      return asset_pids.first if counts.empty?

      # Get key of most downloaded asset.
      key, value = counts.max_by{ |_,v| v }
      key
    end
  end
end
