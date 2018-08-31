module AcademicCommons
  module Metrics
    class UsageStatistics
      include Enumerable
      include AcademicCommons::Metrics::Output

      attr_reader :to_calculate, :start_date, :end_date, :solr_params, :options, :item_stats

      DEFAULT_OPTIONS = {
        include_streaming: false, order_by: nil, requested_by: nil
      }.freeze

      DEFAULT_SOLR_PARAMS = {
        rows: 100_000, page: 1,
        fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
      }.freeze

      # Create statistics object that calculates usage statistics (views,
      # downloads, and streams) for all the items that match the solr query.
      #
      # The first parameter is an array of all the statistics to calculate. The
      # three following types of statistics can be calculated:
      #  1. `:lifetime`
      #  2. `:period`; total stats during the start and end dates given
      #  3. `:month_by_month`; stats are broken down by month for the date range given
      #
      # The second parameter is the solr search that should be conducted. When
      # calculating period and month by month statistics, a start and end date
      # is required. Order can only be applied when one type of statistics is
      # calculated.
      #
      # @example
      #   solr_params = { q: nil }
      #   AcademicCommons::Metrics::UsageStatistics.new(
      #     :lifetime, solr_params, order_by: 'views'
      #   )
      #
      # @param [Symbol|Array] to_calculate lists statistics that should be calculated
      # @param [Hash] solr_params parameters to conduct solr query with
      # @param [Hash] options options to use when creating/rendering stats
      # @option options [Date|Time] :start_date starting date to calculate stats for, time of day is ignored and set to 00:00
      # @option options [Date|Time] :end_date end date to calculate stats for, time of day is ignored and set to 23:59
      # @option options [Boolean] :include_streaming flag to indicate whether streaming statistics should be calculated
      # @option options [String] :order_by most number of downloads or views, by default orders by title, order can only be done if only one type of stats are calculated
      # @option options [User|nil] :requested_by User that requested the report, nil if no use provided
      def initialize(to_calculate, solr_params, **options)
        @to_calculate = Array.wrap(to_calculate)
        @solr_params = solr_params
        @options = DEFAULT_OPTIONS.merge(options)
        @start_date = options.delete(:start_date)
        @end_date = options.delete(:end_date)
        @totals = { Statistic::VIEW => {}, Statistic::DOWNLOAD => {}, Statistic::STREAM => {} }

        if @to_calculate.include?(:period) || @to_calculate.include?(:month_by_month)
          raise ArgumentError, 'Start date must be provided' unless start_date
          raise ArgumentError, 'End date must be provided' unless end_date
        end

        return if solr_params.blank?

        results = get_solr_documents(solr_params)
        Rails.logger.debug "Solr request returned #{results.count} results."

        # Filtering out embargoed material
        results.reject!(&:embargoed?)
        @item_stats = results.map { |doc| AcademicCommons::Metrics::ItemStats.new(doc) }

        return if @item_stats.empty?

        generate_lifetime_stats
        generate_period_stats
        generate_month_by_month_stats
        order_results
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
        if to_calculate == [:lifetime]
          LIFETIME
        else
          [start_date.strftime(MONTH_KEY), end_date.strftime(MONTH_KEY)].uniq.join(' - ')
        end
      end

      private

      def order_results
        return if to_calculate.count > 1 || to_calculate.first == :month_by_month

        if options[:order_by] == 'views' || options[:order_by] == 'downloads'
          time = to_calculate.first.to_s.titlecase
          event = options[:order_by].singularize.titlecase

          @item_stats.sort! do |x, y|
            y.get_stat(event, time) <=> x.get_stat(event, time)
          end
        end
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

      def generate_lifetime_stats
        return unless to_calculate.include?(:lifetime)
        calculate_stats_for(LIFETIME, Statistic::VIEW)
        calculate_stats_for(LIFETIME, Statistic::DOWNLOAD)
        calculate_stats_for(LIFETIME, Statistic::STREAM) if options[:include_streaming]
      end

      # Generate Period stats if start and end date provided
      def generate_period_stats
        return unless to_calculate.include?(:period)
        calculate_stats_for(PERIOD, Statistic::VIEW, start_date, end_date)
        calculate_stats_for(PERIOD, Statistic::DOWNLOAD, start_date, end_date)
        calculate_stats_for(PERIOD, Statistic::STREAM, start_date, end_date) if options[:include_streaming]
      end

      # For each month get the number of view and downloads for each id and populate
      # them into stats.
      def generate_month_by_month_stats
        return unless to_calculate.include?(:month_by_month)

        months_list.each do |date|
          start = date.beginning_of_month
          final = date.end_of_month
          month_key = start.strftime(MONTH_KEY)

          calculate_stats_for(month_key, Statistic::VIEW, start, final)
          calculate_stats_for(month_key, Statistic::STREAM, start, final) if options[:include_streaming]
          calculate_stats_for(month_key, Statistic::DOWNLOAD, start, final)
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
        params[:sort] = 'title_sort asc' if(params[:sort].blank? || options[:order_by] == 'title')
        params[:fq] = params.fetch(:fq, []).clone << "has_model_ssim:\"#{ContentAggregator.to_class_uri}\""
        # Add filter to remove embargoed items, free_to_read date must be equal to or less than Date.current
        Blacklight.default_index.search(params).documents
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
