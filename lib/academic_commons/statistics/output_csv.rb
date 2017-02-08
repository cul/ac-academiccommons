require 'csv'

module AcademicCommons::Statistics
  module OutputCSV
    #
    # @param [User] requested_by user the report was requested by
    def to_csv_by_month(requested_by: nil) # Monthly breakdown of stats
      # Can only be generated with the per month flag is on
      if self.results.blank?
      #  set_message_and_variables
       return
      end

      CSV.generate do |csv|
        csv.add_row [facet.in?('author_facet', 'author_uni') ? 'Author UNI/Name:' : 'Search criteria:', self.query]
        csv.add_row []
        csv.add_row ['Period Covered by Report', "#{self.start_date.strftime("%b %Y")} to #{self.end_date.strftime("%b %Y")}"]
        csv.add_row []
        csv.add_row ['Report created by:', requested_by.nil? ? "N/A" : "#{requested_by} (#{requested_by.uid})"]
        csv.add_row ['Report created on:', Time.new.strftime("%Y-%m-%d") ]

        add_usage_category(csv, "Views", "View", nil)
        add_usage_category(csv, "Streams", "Streaming", nil) if (options[:include_streaming])
        add_usage_category(csv, "Downloads", "Download", self.download_ids)
      end
    end

    def to_csv
    end

    private

    # Makes each category (View, Download, Streaming) section of csv.
    def add_usage_category(csv, category, key, ids)
      csv.add_row []
      csv.add_row []
      csv.add_row [ "#{category} report:".upcase ]
      csv.add_row [ "Total for period:", self.totals[key].to_s,  "", "", "", "#{category} by Month"]
      csv.add_row [ "Title", "Content Type", "Persistent URL", "Publisher DOI", "Reporting Period Total #{category}"].concat(month_column_headers)

      self.results.each do |item|
        csv.add_row [
          item["title_display"], item["genre_facet"].first, item["handle"], item["doi"],
          self.stats[key][item["id"]].nil? ? 0 : self.stats[key][item["id"]]
        ].concat(make_month_line_stats(key, item["id"]))
      end
    end

    # Populated statistics for each month.
    #
    # @param Array<Array<String>> stats
    def make_month_line_stats(key, id)
     self.months_list.map do |month|
       if key == 'Download'
         download_id = self.download_ids[id]
         stats["#{key} #{month.to_s}"][download_id[0]].nil? ? 0 : stats["#{key} #{month.to_s}"][download_id[0]]
       else
         stats["#{key} #{month.to_s}"][id].nil? ? 0 : stats["#{key} #{month.to_s}"][id]
       end
     end
    end

    # Makes column headers of all months represented in this csv.
    def month_column_headers
      self.months_list.map { |m| m.strftime("%b-%Y") }
    end
  end
end
