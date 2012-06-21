require 'csv'

module StatisticsHelper
   
  def cvsReport
    
    #  + "\r\n" after CSV.generate_line is only for ruby version 1.8.7, with version 1.9.3 it should be removed
    
    startdate = Date.parse(params[:month] + " " + params[:year])
    results, stats, totals = get_author_stats(:startdate => startdate, :include_zeroes => params[:include_zeroes], :author_id => params[:author_id])
    
    
    csv = "Author UNI/Name: " + params[:author_id].to_s + "\r\n"
    csv += CSV.generate_line(["Total for " + params[:month].to_s + " " + params[:year].to_s, 
                            "",
                            "",
                            "", 
                            totals["View"].to_s, 
                            totals["Download"].to_s]) + "\r\n"
                            
    csv += CSV.generate_line([ "Title", 
                               "Content Type", 
                               "Permanent URL",
                               "DOI", 
                               "Views", 
                               "Downloads"
                               ]) + "\r\n"

    results.each do |item|

    csv += CSV.generate_line([item["title_display"],
                              item["genre_facet"],
                              item["handle"],
                              item["doi"],
                              stats["View"][item["id"][0]].nil? ? 0 : stats["View"][item["id"][0]],
                              stats["Download"][item["id"][0]].nil? ? 0 : stats["Download"][item["id"][0]]
                              ]) + "\r\n"
    end

    return csv
  end

  def get_author_stats(options = {})
    startdate = options[:startdate]
    author_id = options[:author_id]
    enddate = startdate + 1.month

    if(author_id =~ /^\S+\d+$/)
      solr_query = "author_uni:#{author_id}"
    else
      solr_query = "author_facet:\"#{author_id}\""
    end    

    results = Blacklight.solr.find(:per_page => 100000, 
                                   :sort => "title_display asc", 
                                   :fq => solr_query,
                                   :fl => "title_display,id,handle,doi,genre_facet", 
                                   :page => 1
                                   )["response"]["docs"]
    
     logger.info "results: " + results.to_s
     logger.info "\n\n\n " 
    
    ids = results.collect { |r| r['id'].to_s.strip }
    
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    
    download_ids = Hash.new { |h,k| h[k] = [] } 
    ids.each do |doc_id|
      download_ids[doc_id] |= fedora_server.item(doc_id).listMembers.collect(&:pid)
#      download_ids[doc_id] |=  fedora_server.item(doc_id).describedBy.collect(&:pid)
    end
    stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 }}
    totals = Hash.new { |h,k| h[k] = 0 }


    stats['View'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", ids,startdate, enddate])

    stats_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", download_ids.values.flatten,startdate, enddate])
    download_ids.each_pair do |doc_id, downloads|

      stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
    end


    stats['View Lifetime'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?)", ids])


    stats_lifetime_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?)" , download_ids.values.flatten])
    download_ids.each_pair do |doc_id, downloads|

      stats['Download Lifetime'][doc_id] = downloads.collect { |download_id| stats_lifetime_downloads[download_id] || 0 }.sum
    end
    stats.keys.each { |key| totals[key] = stats[key].values.sum }


    stats['View'] = convertOrderedHash(stats['View'])
    stats['View Lifetime'] = convertOrderedHash(stats['View Lifetime'])

    results.reject! { |r| (stats['View'][r['id'][0]] || 0) == 0 &&  (stats['Download'][r['id']] || 0) == 0 } unless params[:include_zeroes]
    results.sort! do |x,y|
      result = (stats['Download'][y['id']] || 0) <=> (stats['Download'][x['id']] || 0) 
      result = x["title_display"] <=> y["title_display"] if result == 0
      #result = x["handle"] <=> y["handle"] if result == 0
      result
    end

    return results, stats, totals

  end


end
