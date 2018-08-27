require 'csv'
module AcademicCommons
  module Metrics
    module Output
      # This module contains three options to export a CSV of the data (lifetime,
      # time_period and month_by_month). It also offers methods to return the
      # data in an array of an array. These additional methods can be used to
      # render the data in different formats.
      MONTH_KEY = '%b %Y'.freeze

      # Returns array with details of usage stats generated.
      def report_details(period_covered: nil)
        [
          ['Period Covered by Report:', period_covered || time_period],
          ['Raw Query:', solr_params.inspect],
          ['Order:', (options[:order_by] || 'Title').titlecase],
          ['Report created by:', options[:requested_by].nil? ? 'N/A' : "#{options[:requested_by]} (#{options[:requested_by].uid})"],
          ['Report created on:', Time.current.strftime('%Y-%m-%d')],
          ['Total number of items:', count]
        ]
      end

      # Returns CSV with statistics for the time period given.
      def time_period_csv
        CSV.generate do |csv|
          report_details.each { |a| csv.add_row(a) }
          csv.add_row [] # Blank row
          time_period_table.each { |a| csv.add_row(a) }
        end
      end

      # Returns CSV with lifetime statistics.
      def lifetime_csv
        CSV.generate do |csv|
          report_details(period_covered: 'Lifetime').each { |a| csv.add_row(a) }
          csv.add_row [] # Blank row
          lifetime_table.each { |a| csv.add_row(a) }
        end
      end

      # Returns CSV with statistics broken down month by month for the time period
      # given. Two tables are returned one for view stats and one for download stats.
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

      def time_period_table
        summary_table(AcademicCommons::Metrics::UsageStatistics::PERIOD)
      end

      def lifetime_table
        summary_table(AcademicCommons::Metrics::UsageStatistics::LIFETIME)
      end

      # Event should be one of Statistic::VIEW or Statistic::DOWNLOAD
      def month_by_month_table(event)
        headers = ['Title', 'Genre', 'DOI', 'Record Creation Date']
        month_column_headers = months_list.map { |m| m.strftime(MONTH_KEY) }
        headers.concat(month_column_headers)
        table = [headers]

        each do |item|
          monthly_stats = months_list.map { |m| item.get_stat(event, m.strftime(MONTH_KEY)) }
          table << [
            item.document.title, item.document.genre, item.document.doi,
            Date.strptime(item.document.created_at).strftime('%m/%d/%Y')
          ].concat(monthly_stats)
        end

        table
      end

      private

      def summary_table(time)
        table = [['Title', 'Genre', 'DOI', 'Record Creation Date', 'Views', 'Downloads']]

        each do |item|
          table << [
            item.document.title, item.document.genre, item.document.doi,
            Date.strptime(item.document.created_at).strftime('%m/%d/%Y'),
            item.get_stat(Statistic::VIEW, time), item.get_stat(Statistic::DOWNLOAD, time)
          ]
        end

        table
      end
    end
  end
end
