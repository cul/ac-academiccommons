require 'csv'

module StatisticsHelper
   
  def cvsReport(results, stats, totals)
    
    csv = "Author UNI: " + params[:author_id].to_s + "\r\n"
    csv += CSV.generate_line(["Total for " + params[:month].to_s + " " + params[:year].to_s, 
                            "", 
                            totals["View"].to_s, 
                            totals["Download"].to_s]) + "\r\n"
                            
    csv += CSV.generate_line(["Title", "Link",  "Views", "Downloads"]) + "\r\n"

    results.each do |item|
      csv += CSV.generate_line([item["title_display"],
                              "http://" + request.host_with_port + catalog_path(item["id"]),
                              stats["View"][item["id"][0]],
                              stats["Download"][item["id"][0]]]) + "\r\n"
    end

    return csv
  end

end
