require 'csv'

module AcademicCommons::Metrics
  module OutputCSV
    MONTH_KEY = '%b %Y'.freeze

    # Creates CSV with usage stats for the time period given. If a start and end
    # date were not specified Lifetime stats are displayed.
    def to_csv
      CSV.generate do |csv|
        csv.add_row [ 'Time Period:', time_period]
        csv.add_row []

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

    # Returns array with details of usage stats
    def report_details(period_covered: nil)
      [
        ['Period Covered by Report:', period_covered || self.time_period],
        ['Raw Query:', self.solr_params.inspect],
        ['Order:', (self.options[:order_by] || 'Title').titlecase],
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
  end
end
