require 'csv'

module AcademicCommons::Metrics
  module OutputCSV
    MONTH_KEY = '%b %Y'.freeze

    # CSV with monthly breakdown of stats for each event.
    #
    # @param [User] requested_by user the report was requested by
    def to_csv_by_month(requested_by: nil)
      # Can only be generated with the per month flag is on

      CSV.generate do |csv|
        # csv.add_row [facet.in?('author_facet', 'author_uni') ? 'Author UNI/Name:' : 'Search criteria:', self.query]
        csv.add_row [self.solr_params.inspect]
        csv.add_row []
        csv.add_row ['Period Covered by Report', time_period]
        csv.add_row []
        csv.add_row ['Report created by:', requested_by.nil? ? 'N/A' : "#{requested_by} (#{requested_by.uid})"]
        csv.add_row ['Report created on:', Time.new.strftime('%Y-%m-%d') ]

        add_usage_category(csv, 'Views', Statistic::VIEW)
        add_usage_category(csv, 'Streams', Statistic::STREAM) if (options[:include_streaming])
        add_usage_category(csv, 'Downloads', Statistic::DOWNLOAD)
      end
    end

    # Creates CSV with usage stats for the time period given. If a start and end
    # date were not specified Lifetime stats are displayed.
    def to_csv
      CSV.generate do |csv|
        csv.add_row [ 'Time Period:', time_period]
        csv.add_row []

        # csv.add_row [ 'FACET', 'ITEM']
        # params[:f].each do |key, value|
        #   csv.add_row [facet_names[key.to_s], value.first]
        # end
        # csv.add_row []

        csv.add_row ['Query:', solr_params.inspect] # TODO: Pretty print for solr params.
        time = lifetime_only? ? 'Lifetime' : 'Period'

        totals_row = [self.count, '', '', total_for(Statistic::VIEW, time), total_for(Statistic::DOWNLOAD, time)]
        totals_row << total_for(Statistic::STREAM, time) if options[:include_streaming]
        csv.add_row totals_row

        heading = ['#', 'TITLE', 'GENRE', 'VIEWS', 'DOWNLOADS', 'DEPOSIT DATE', 'HANDLE / DOI']
        heading.insert(5, 'STREAMS') if options[:include_streaming]
        csv.add_row heading

        self.each_with_index do |item, idx|
          document = item.document
          item_row = [
            idx + 1, document['title_ssi'],
            document.fetch('genre_facet', []).first,
            item.get_stat(Statistic::VIEW, time),
            item.get_stat(Statistic::DOWNLOAD, time),
            Date.strptime(document['record_creation_date']).strftime('%m/%d/%Y'),
            document['handle']
          ]
          item_row.insert(5, item.get_stat(Statistic::STREAM, time)) if options[:include_streaming]
          csv.add_row item_row
        end
      end
    end

    private

    # Makes each category (View, Download, Streaming) section of csv.
    def add_usage_category(csv, category, key)
      csv.add_row []
      csv.add_row []
      csv.add_row [ "#{category} report:".upcase ]
      csv.add_row [ 'Total for period:', total_for(key, 'Period').to_s,  '', '', '', "#{category} by Month"]
      month_column_headers = self.months_list.map { |m| m.strftime('%b-%Y') }
      csv.add_row [ 'Title', 'Content Type', 'Persistent URL', 'Publisher DOI', "Reporting Period Total #{category}"].concat(month_column_headers)

      self.each do |item_stat|
        id = item_stat.id
        monthly_stats = self.months_list.map { |m| item_stat.get_stat(key, m.strftime(MONTH_KEY)) }
        document = item_stat.document
        csv.add_row [
          document['title_ssi'], document['genre_facet'].first, document['handle'],
          document['doi'], item_stat.get_stat(key, 'Period')
        ].concat(monthly_stats)
      end
    end
  end
end
