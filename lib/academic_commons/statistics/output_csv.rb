require 'csv'

module AcademicCommons::Statistics
  module OutputCSV
    MONTH_KEY = '%b %Y'

    #
    # @param [User] requested_by user the report was requested by
    def to_csv_by_month(requested_by: nil) # Monthly breakdown of stats
      # Can only be generated with the per month flag is on
      CSV.generate do |csv|
        csv.add_row [facet.in?('author_facet', 'author_uni') ? 'Author UNI/Name:' : 'Search criteria:', self.query]
        csv.add_row []
        csv.add_row ['Period Covered by Report', "#{self.start_date.strftime("%b %Y")} to #{self.end_date.strftime("%b %Y")}"]
        csv.add_row []
        csv.add_row ['Report created by:', requested_by.nil? ? "N/A" : "#{requested_by} (#{requested_by.uid})"]
        csv.add_row ['Report created on:', Time.new.strftime("%Y-%m-%d") ]

        add_usage_category(csv, "Views", "View")
        add_usage_category(csv, "Streams", "Streaming") if (options[:include_streaming])
        add_usage_category(csv, "Downloads", "Download")
      end
    end

    def to_csv
    end

    private

    # Makes each category (View, Download, Streaming) section of csv.
    def add_usage_category(csv, category, key)
      csv.add_row []
      csv.add_row []
      csv.add_row [ "#{category} report:".upcase ]
      csv.add_row [ "Total for period:", total_for(key, "Period").to_s,  "", "", "", "#{category} by Month"]
      month_column_headers = self.months_list.map { |m| m.strftime("%b-%Y") }
      csv.add_row [ "Title", "Content Type", "Persistent URL", "Publisher DOI", "Reporting Period Total #{category}"].concat(month_column_headers)

      self.each do |item_stat|
        id = item_stat.id
        monthly_stats = self.months_list.map { |m| item_stat.get_stat(key, m.strftime(MONTH_KEY)) }
        document = item_stat.document
        csv.add_row [
          document["title_display"], document["genre_facet"].first, document["handle"],
          document["doi"], item_stat.get_stat(key, "Period")
        ].concat(monthly_stats)
      end
    end
  end
end
