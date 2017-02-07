module AcademicCommons
  class UsageStatistics
    include AcademicCommons::Statistics::OutputCSV

    attr_reader :start_date, :end_date, :months_list, :facet, :query
    attr_accessor :stats, :totals, :results, :download_ids, :ids, :options

    DEFAULT_OPTIONS = {
      include_zeroes: true, include_streaming: false, per_month: false, recent_first: false
    }
    VIEW = 'view_'
    DOWNLOAD = 'download_'

    # Create statistics object that calculates usage statistics for all the
    # items that match the query.
    #
    # @param [Date] start_date
    # @param [Date] end_date
    # @param [String] query solr query
    # @param [String] facet
    # @param [String] order_by
    # @param [Hash] options options to use when creating/rendering stats
    # @option options [Boolean] :include_zeroes flag to indicate whether records with no usage stats should be included
    # @option options [Boolean] :include_streaming
    # @option options [Boolean] :per_month flag to organize statistics by month
    # @option options [Boolean] :recent_first if true, when listing months list most recent month first
    def initialize(start_date, end_date, query, facet, order_by, options = {})
      @start_date = start_date
      @end_date = end_date
      @query = query
      @facet = facet
      self.options = DEFAULT_OPTIONS.merge(options)
      @months_list = (options[:per_month]) ? make_months_list(start_date, end_date, options[:recent_first]) : nil
      generate_stats(start_date, end_date, query, self.months_list, options[:include_zeroes], facet, options[:include_streaming_views], order_by)
    end

    private

    # Returns statistics for all the items returned by a solr query
    def generate_stats(startdate, enddate, query, months_list, include_zeroes, facet, include_streaming_views, order_by)
      Rails.logger.debug "In generate_stats for #{query}"
      return if query.blank?

      self.results = make_solr_request(facet, query)
      Rails.logger.debug "Solr request returned #{self.results.count} results."

      return if self.results.nil?

      init_holders(self.results)

      Rails.logger.debug "#{ids.count} results after init_holders"

      process_stats(startdate, enddate)

      self.results.reject! { |r| (self.stats['View'][r['id']] || 0) == 0 &&  (self.stats['Download'][r['id']] || 0) == 0 } unless include_zeroes

      if(order_by == 'views' || order_by == 'downloads')
        self.results.sort! do |x,y|
          if(order_by == 'downloads')
            result = (stats['Download'][y['id']] || 0) <=> (self.stats['Download'][x['id']] || 0)
          end
          if(order_by == 'views')
            result = (self.stats['View'][y['id']] || 0) <=> (self.stats['View'][x['id']] || 0)
          end
          result
        end
      end

      if(months_list != nil)
        process_stats_by_month(self.stats, self.totals, self.ids, self.download_ids, startdate, enddate, months_list)
      end
    end

    # Creates list of month-year strings in order from the startdate to the
    # enddate given.
    #
    # @param recent_first flag that reverses array
    def make_months_list(startdate, enddate, recent_first = false)
      months = []
      date = startdate
      while date <= enddate
        months << date
        date += 1.month
      end

      (recent_first) ? months.reverse : months
    end

    # Generates base line objects to hold usage statistic information.
    #
    # @param [] results solr results from query
    # @return [Hash] stats hash keeping track of item views and downloads
    # @return [Hash] totals
    # @return [Array<String>] id all aggregator pids
    # @return [Hash] download_ids all downloadable item pids
    def init_holders(results)
      self.ids = results.collect { |r| r['id'].to_s.strip } # Get all the aggregator pids.

      self.download_ids = Hash.new { |h,k| h[k] = [] }

      # Get pids of all downloadable files.
      self.ids.each do |doc_id|
        download_ids[doc_id] |= ActiveFedora::Base.find(doc_id).list_members(pids_only: true)
      end

      self.stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 }}
      self.totals = Hash.new { |h,k| h[k] = 0 }
    end

    def process_stats(startdate, enddate)
      Rails.logger.debug "In process_stats for #{ids}"
      enddate = enddate + 1.months

      self.stats['View'] = Statistic.group(:identifier).where("event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", self.ids, startdate, enddate).count
      self.stats['Streaming'] = Statistic.group(:identifier).where("event = 'Streaming' and identifier IN (?) AND at_time BETWEEN ? and ?", self.ids, startdate, enddate).count

      stats_downloads = Statistic.group(:identifier).where("event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", self.download_ids.values.flatten, startdate, enddate).count

      self.download_ids.each_pair do |doc_id, downloads|
        self.stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
      end

      self.stats['View'] = convert_ordered_hash(self.stats['View'])

      self.stats['View Lifetime'] = Statistic.group(:identifier).where("event = 'View' and identifier IN (?)", self.ids).count
      self.stats['Streaming Lifetime'] = Statistic.group(:identifier).where("event = 'Streaming' and identifier IN (?)", self.ids).count

      stats_lifetime_downloads = Statistic.group(:identifier).where("event = 'Download' and identifier IN (?)", self.download_ids.values.flatten).count

      self.download_ids.each_pair do |doc_id, downloads|
        self.stats['Download Lifetime'][doc_id] = downloads.collect { |download_id| stats_lifetime_downloads[download_id] || 0 }.sum
      end

      self.stats.keys.each { |key| self.totals[key] = self.stats[key].values.sum }

      self.stats['View Lifetime'] = convert_ordered_hash(stats['View Lifetime'])

      Rails.logger.debug("statistics hash: #{self.stats.inspect}")
    end

    # For each month get the number of view and downloads for each id and populate
    # them into stats.
    def process_stats_by_month(stats, totals, ids, download_ids, startdate, enddate, months_list)
      months_list.each do |month|
        contdition = month.strftime("%Y-%m") + "%"

        self.stats[VIEW + month.to_s] = Statistic.group(:identifier).where("event = 'View' and identifier IN (?) and at_time like ?", self.ids, contdition).count
        self.stats[DOWNLOAD + month.to_s] = Statistic.group(:identifier).where("event = 'Download' and identifier IN (?) and at_time like ?", self.download_ids.values.flatten, contdition).count
      end
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

      return if facet_query == nil && q == nil

      Blacklight.default_index.search(
        :rows => 100000, :sort => sort, :q => q, :fq => facet_query,
        :fl => "title_display,id,handle,doi,genre_facet", :page => 1
      )["response"]["docs"]
    end

    def convert_ordered_hash(ohash)
      a =  ohash.to_a
      oh = {}
      a.each{|x|  oh[x[0]] = x[1]}
      return oh
    end
  end
end
