module AcademicCommons
  module Metrics
    class UsageStatistics
      include Enumerable
      include AcademicCommons::Metrics::Output

      attr_reader :start_date, :end_date, :solr_params, :include_streaming,
                  :requested_by, :item_stats, :ordered_by

      DEFAULT_OPTIONS = {
        include_streaming: false, requested_by: nil
      }.freeze

      DEFAULT_SOLR_PARAMS = {
        rows: 100_000, page: 1,
        fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
      }.freeze

      REQUIRED_FILTERS = ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""].freeze

      # Create statistics object that calculates usage statistics (views,
      # downloads, and streams) for all the items that match the solr query.
      # The class accepts a number of options that may be necessary depending on
      # what statistics are to be calculate.
      #
      # Three different type of statistics can be generated (by calling the
      # appropriate method):
      #  1. `.calculate_lifetime`
      #  2. `.calculate_period` total stats during the start and end dates given
      #  3. `.calculate_month_by_month` stats are broken down by month for the date range given
      #
      # After stats have been calculated they can also be ordered based on the
      # type of statsitics (lifetime, view, month_by_month) and the event (view,
      # download, streaming). Stats cannot be ordered until after they have been calculated.
      #
      # @example
      #   usage_stats = AcademicCommons::Metrics::UsageStatistics.new(solr_params: { q: nil })
      #                                                          .calculate_lifetime
      #                                                          .order_by(:lifetime, Statistic::VIEW)
      #
      # @param [Hash] solr_params parameters to conduct solr query with
      # @param [Date|Time] start_date starting date to calculate stats for, time of day is ignored and set to 00:00
      # @param [Date|Time] end_date end date to calculate stats for, time of day is ignored and set to 23:59
      # @param [Boolean] include_streaming flag to indicate whether streaming statistics should be calculated
      # @param [User|nil] requested_by User that requested the report, nil if no use provided
      def initialize(solr_params: {}, start_date: nil, end_date: nil, include_streaming: false, requested_by: nil)
        @solr_params       = solr_params
        @start_date        = start_date
        @end_date          = end_date
        @include_streaming = include_streaming
        @requested_by      = requested_by

        @calculated = []
        @totals = { Statistic::VIEW => {}, Statistic::DOWNLOAD => {}, Statistic::STREAM => {} }

        # return if solr_params.blank?

        results = get_solr_documents(solr_params)
        Rails.logger.debug "Solr request returned #{results.count} results."

        # Filtering out embargoed material
        results.reject!(&:embargoed?)
        @item_stats = results.map { |doc| AcademicCommons::Metrics::ItemStats.new(doc) }

        # return if @item_stats.empty?
      end

      def item(id)
        (item = @item_stats.find { |i| i.id == id }) ? item : raise("Could not find #{id}")
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
        if @calculated == [:lifetime]
          LIFETIME.to_s.titlecase
        else
          [start_date.strftime(MONTH_KEY), end_date.strftime(MONTH_KEY)].uniq.join(' - ')
        end
      end

      # Order items by the provided time and event stats.
      #
      # @param [String] time one of Period, Lifetime, Month Year
      # @param [String] event one of View, Download or Stream
      def order_by(time, event)
        @item_stats.sort! do |x, y|
          y.get_stat(event, time) <=> x.get_stat(event, time)
        end
        @ordered_by = "#{time} #{event.pluralize}"
        self
      end

      def calculate_lifetime
        return StandardError, 'Already calculated stats for lifetime' if @calculated.include?(:lifetime)
        calculate_stats_for(LIFETIME, Statistic::VIEW)
        calculate_stats_for(LIFETIME, Statistic::DOWNLOAD)
        calculate_stats_for(LIFETIME, Statistic::STREAM) if include_streaming
        @calculated << :lifetime
        self
      end

      # Generate Period stats if start and end date provided
      def calculate_period
        return StandardError, 'Already calculated stats for period' if @calculated.include?(:period)
        check_for_dates
        calculate_stats_for(PERIOD, Statistic::VIEW, start_date, end_date)
        calculate_stats_for(PERIOD, Statistic::DOWNLOAD, start_date, end_date)
        calculate_stats_for(PERIOD, Statistic::STREAM, start_date, end_date) if include_streaming
        @calculated << :period
        self
      end

      # For each month get the number of view and downloads for each id and populate
      # them into stats.
      def calculate_month_by_month
        return StandardError, 'Already calculated stats for period' if @calculated.include?(:month_by_month)
        check_for_dates

        months_list.each do |date|
          start = date.beginning_of_month
          final = date.end_of_month
          month_key = start.strftime(MONTH_KEY)

          calculate_stats_for(month_key, Statistic::VIEW, start, final)
          calculate_stats_for(month_key, Statistic::STREAM, start, final) if include_streaming
          calculate_stats_for(month_key, Statistic::DOWNLOAD, start, final)
        end
        @calculated << :month_by_month
        self
      end

      private

      def check_for_dates
        raise ArgumentError, 'Start date must be provided' unless start_date
        raise ArgumentError, 'End date must be provided' unless end_date
      end

      # Creates list of month and year strings in order from the startdate to the
      # enddate given.
      def months_list
        unless @months_list
          months = []
          date = start_date
          while date <= end_date
            months << date
            date += 1.month
          end
          @month_list = months
        end

        @month_list
      end

      def add_item_stats(event, time, stats)
        @item_stats.each do |i|
          value = stats.key?(i.id) ? stats[i.id] : 0
          i.add_stat(event, time, value)
        end
      end

      def ids
        @ids ||= @item_stats.collect(&:id)
      end

      # Map of IDs from item id to most downloaded asset id.
      def item_to_asset_ids
        @item_to_asset_ids ||= @item_stats.map { |item| [item.id, most_downloaded_asset(item.document)] }.to_h
      end

      def calculate_stats_for(time_key, event, start_date = nil, end_date = nil)
        stats = case event
                when Statistic::VIEW, Statistic::STREAM
                  Statistic.event_count(ids, event, start_date: start_date, end_date: end_date)
                when Statistic::DOWNLOAD
                  downloads = Statistic.event_count(item_to_asset_ids.values, event, start_date: start_date, end_date: end_date)
                  map_download_stats_to_aggregator(downloads)
                end

        @item_stats.each do |i|
          value = stats.key?(i.id) ? stats[i.id] : 0
          i.add_stat(event, time_key, value)
        end
      end

      # Maps download stats from asset pids to aggregator pids.
      def map_download_stats_to_aggregator(download_stats)
        downloads = {}
        item_to_asset_ids.each_pair do |id, asset_id|
          if (num = download_stats[asset_id])
            downloads[id] = num
          end
        end
        downloads
      end

      def get_solr_documents(params)
        params = params.merge(DEFAULT_SOLR_PARAMS)
        params[:sort] = 'title_sort asc'

        params[:fq] = ensure_necessary_filters(params[:fq])
        # Add filter to remove embargoed items, free_to_read date must be equal to or less than Date.current
        Blacklight.default_index.search(params).documents
      end

      def ensure_necessary_filters(fq)
        fq ||= []
        fq + (REQUIRED_FILTERS - fq)
      end

      # Most downloaded asset over entire lifetime.
      # Eventually may have to reevaluate this for queries that are for a specific
      # time range. For now, we are okay with this assumption.
      def most_downloaded_asset(doc)
        asset_ids = doc.assets.map(&:id)

        return asset_ids.first if asset_ids.count == 1

        # Get the higest value stored here.
        counts = Statistic.event_count(asset_ids, Statistic::DOWNLOAD)

        # Return first pid, if items have never been downloaded.
        return asset_ids.first if counts.empty?

        # Get key of most downloaded asset.
        key, = counts.max_by { |_, v| v }
        key
      end
    end
  end
end
