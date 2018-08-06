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
        # csv.add_row [facet.in?('author_ssim', 'author_uni_ssim') ? 'Author UNI/Name:' : 'Search criteria:', self.query]
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

        heading = ['#', 'TITLE', 'GENRE', 'VIEWS', 'DOWNLOADS', 'DEPOSIT DATE', 'DOI']
        heading.insert(5, 'STREAMS') if options[:include_streaming]
        csv.add_row heading

        self.each_with_index do |item, idx|
          document = item.document
          item_row = [
            idx + 1, document['title_ssi'],
            document.fetch('genre_ssim', []).first,
            item.get_stat(Statistic::VIEW, time),
            item.get_stat(Statistic::DOWNLOAD, time),
            Date.strptime(document['record_creation_dtsi']).strftime('%m/%d/%Y'),
            document['cul_doi_ssi']
          ]
          item_row.insert(5, item.get_stat(Statistic::STREAM, time)) if options[:include_streaming]
          csv.add_row item_row
        end
      end
    end

    # display: month_to_month
    #          lifetime_summary
    #          period_summary
    # def to_csv(type)
    #
    # Headers (should be the same for both)
    #
    # if lifetime or range
    #   fetch table
    # elsif month to month, can only do month to month if the month to month flag was choosen
    #   fetch different table (x2)
    # end

    # Returns array with details of usage stats
    def report_details(period_covered: nil)
      [
        ['Period Covered by Report:', period_covered || self.time_period],
        ['Raw Query:', self.solr_params.inspect],
        ['Order:', self.options[:order]],
        ['Report created by:', options[:requested_by].nil? ? 'N/A' : "#{options[:requested_by]} (#{options[:requested_by].uid})"],
        ['Report created on:', Time.current.strftime('%Y-%m-%d')],
        ['Total number of items:', self.count]
      ]
    end

    def time_period_csv
      CSV.generate do |csv|
        report_details.each { |a| csv.add_row(a) }
        csv.add_row [] # Blank row
        time_period_summary.each { |a| csv.add_row(a) }
      end
    end

    def lifetime_csv
      CSV.generate do |csv|
        report_details(period_covered: 'Lifetime').each { |a| csv.add_row(a) }
        csv.add_row [] # Blank row
        lifetime_summary.each { |a| csv.add_row(a) }
      end
    end

    def month_by_month_csv
      CSV.generate do |csv|
        report_details.each { |a| csv.add_row(a) }
        csv.add_row [] # Blank row
        csv.add_row ['VIEWS']
        month_by_month_table(Statistic::VIEW).each { |a| csv.add_row(a) }
        csv.add_row [] # Blank row
        csv.add_row ['DOWNLOADS']
        month_by_month_table(Statistic::DOWNLOAD).each { |a| csv.add_row(a) }
      end
    end

    def time_period_summary
      summary_table(AcademicCommons::Metrics::UsageStatistics::PERIOD)
    end

    def lifetime_summary
      summary_table(AcademicCommons::Metrics::UsageStatistics::LIFETIME)
    end

    def summary_table(time)
      table = [['Title', 'Genre', 'DOI', 'Record Creation Date', 'Views', 'Downloads']]

      self.each do |item|
        table << [
          item.document.title, item.document.genre, item.document.doi,
          Date.strptime(item.document.created_at).strftime('%m/%d/%Y'),
          item.get_stat(Statistic::VIEW, time), item.get_stat(Statistic::DOWNLOAD, time)
        ]
      end

      table
    end

    # event should be one of Statistic::VIEW or Statistic::DOWNLOAD
    def month_by_month_table(event)
      headers = ['Title', 'Genre', 'DOI', 'Record Creation Date']
      month_column_headers = self.months_list.map { |m| m.strftime('%b-%Y') }
      headers.concat(month_column_headers)
      table = [headers]

      self.each do |item|
        id = item.id
        monthly_stats = self.months_list.map { |m| item.get_stat(event, m.strftime(MONTH_KEY)) }
        table << [
          item.document.title, item.document.genre, item.document.doi,
          Date.strptime(item.document.created_at).strftime('%m/%d/%Y')
        ].concat(monthly_stats)
      end

      table
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
          document['title_ssi'], document['genre_ssim'].first, document['cul_doi_ssi'],
          document['publisher_doi_ssi'], item_stat.get_stat(key, 'Period')
        ].concat(monthly_stats)
      end
    end
  end
end
