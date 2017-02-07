require 'csv'

module AcademicCommons::Statistics
  module OutputCSV
    #
    # @param [User] requested_by user the report was requested by
    def to_csv_by_month(requested_by: nil) # Monthly breakdown of stats
      if self.results.blank?
      #  set_message_and_variables
       return
      end

      first_line = if facet.in?('author_facet', 'author_uni')
                     "Author UNI/Name: ,#{self.query}"
                   else
                     "Search criteria: ,#{self.query}"
                   end

      CSV.generate(first_line) do |csv|
        csv.add_row ['Period covered by Report']
        csv.add_row [ "from:", "to:" ]
        csv.add_row [ self.start_date.strftime("%b-%Y"),  self.end_date.strftime("%b-%Y") ]
        csv.add_row [ "Date run:" ]
        csv.add_row [ Time.new.strftime("%Y-%m-%d") ]
        csv.add_row [ "Report created by:" ]
        csv.add_row [  requested_by.nil? ? "N/A" : "#{requested_by} (#{requested_by.uid})" ]

        add_usage_category(csv, "Views", "View", nil)
        if(options[:include_streaming])
         add_usage_category(csv, "Streams", "Streaming", nil)
        end
        add_usage_category(csv, "Downloads", "Download", self.download_ids)
      end

    end

    def to_csv
    end

    private

    # Makes each category (View, Download, Streaming) section of csv.
    def add_usage_category(csv, category, key, ids)
      csv.add_row [ "" ]
      csv.add_row [ "#{category} report:" ]
      csv.add_row [ "Total for period:", "", "", "", self.totals[key].to_s].concat(make_months_header("#{category} by Month"))
      csv.add_row [ "Title", "Content Type", "Persistent URL", "DOI", "Reporting Period Total #{category}"].concat(make_month_line(self.months_list))

      self.results.each do |item|
        csv.add_row [
          item["title_display"], item["genre_facet"].first, item["handle"], item["doi"],
          self.stats[key][item["id"]].nil? ? 0 : self.stats[key][item["id"]]
        ].concat(make_month_line_stats(self.stats, self.months_list, item["id"], ids))
      end
    end

    # Populated statistics for each month.
    #
    # @param Array<Array<String>> stats
    def make_month_line_stats(stats, months_list, id, download_ids)
     line = []

     months_list.each do |month|

       if(download_ids != nil)
         download_id = download_ids[id]
         line << (stats[DOWNLOAD + month.to_s][download_id[0]].nil? ? 0 : stats[DOWNLOAD + month.to_s][download_id[0]])
       else
         line << (stats[VIEW + month.to_s][id].nil? ? 0 : stats[VIEW + month.to_s][id])
       end

     end
     return line
    end

    # Creates part of the header above the column names.
    def make_months_header(first_item)
      header = Array.new(self.months_list.size, "")
      header[0] = first_item
      header
    end

    # Makes column headers of all months represented in this csv.
    def make_month_line(months_list)
      months_list.map { |m| m.strftime("%b-%Y") }
    end
  end
end
