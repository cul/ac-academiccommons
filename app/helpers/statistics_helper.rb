require 'csv'

module StatisticsHelper
   
  def cvsReport(startdate, enddate, author, include_zeroes)
    
    #  + "\r\n" after CSV.generate_line is only for ruby version 1.8.7, with version 1.9.3 it should be removed

    months_list = make_months_list(startdate, enddate)
    results, stats, totals = get_author_stats(startdate, enddate, author, months_list, include_zeroes)
    #:startdate => startdate, :include_zeroes => params[:include_zeroes], :author_id => params[:author_id])
    
    
    csv = "Author UNI/Name: ," + author.to_s + "\r\n"
    csv += CSV.generate_line( [ "Total for period", 
                                "",
                                "",
                                "", 
                                totals["View"].to_s, 
                                totals["Download"].to_s] ) + "\r\n"
                            
    csv += CSV.generate_line([ "Title", 
                               "Content Type", 
                               "Permanent URL",
                               "DOI", 
                               "Reporting Period Total Views", 
                               "Reporting Period Total Downloads"
                               ].concat( months_list.values )) + "\r\n"

    results.each do |item|

    csv += CSV.generate_line([item["title_display"],
                              item["genre_facet"],
                              item["handle"],
                              item["doi"],
                              stats["View"][item["id"][0]].nil? ? 0 : stats["View"][item["id"][0]],
                              stats["Download"][item["id"][0]].nil? ? 0 : stats["Download"][item["id"][0]]
                              ].concat( make_month_line(stats, months_list, item["id"][0])) ) + "\r\n"
       
    # months_list.each do |key, value|                       
      # logger.info " ========= month counters " + [item["id"][0]].to_s + " - " + key.to_s + " - " +  stats[key.to_s].to_s
    # end
                              
    end
    
    # months_list.each do |key, value|
#     
    # logger.info " ======= month: " + key.to_s + " " +  value.to_s
#     
    # end


    return csv
  end


  def make_month_line(stats, months_list, id)
    
    line = []
    
    months_list.keys.each do |month|                       
      
      logger.info "======= " + month + " - " + stats[month.to_s].to_s + " - " + stats[month.to_s][id].to_s + " - " + id
      
      line << (stats[month.to_s][id].nil? ? 0 : stats[month.to_s][id])
    end    
    
    return line
  end


  def process_stats_by_month(stats, totals, ids, download_ids, startdate, enddate, months_list)
    
    logger.info "=================== process_stats_by_month =============="
    
    months_list.keys.each do |month|
      
      contdition = month.to_s + "%"
      
      #stats[month.to_s] = Statistic.count(:group => "DATE_FORMAT(at_time,'%Y-%m')", :conditions => ["event = 'View' and identifier IN (?) and at_time like ?", ids, contdition])
      
      #stats[month.to_s] = Statistic.find_by_sql("SELECT COUNT(*) AS count_all, identifier AS identifier FROM statistics WHERE event = 'View' and identifier IN (?) and at_time like '" + contdition +"' GROUP BY identifier")
      
      #stats[month.to_s] = [4, "ac:130854"]
      
      stats[month.to_s] = Hash["ac:130854", 60] 
      
    end
    
    # stats['View'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", ids, startdate, enddate])
# 
    # stats_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", download_ids.values.flatten, startdate, enddate])
# 
    # download_ids.each_pair do |doc_id, downloads|
      # stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
    # end    
#     
    # stats['View'] = convertOrderedHash(stats['View'])

  end

  

  def get_author_stats(startdate, enddate, author_id, months_list, include_zeroes)

    results = make_solar_request(author_id)

    stats, totals, ids, download_ids = init_holders(results, startdate, enddate)
    
    
      
    process_stats(stats, totals, ids, download_ids, startdate, enddate)
    
      results.reject! { |r| (stats['View'][r['id'][0]] || 0) == 0 &&  (stats['Download'][r['id']] || 0) == 0 } unless include_zeroes
        
      results.sort! do |x,y|
        result = (stats['Download'][y['id']] || 0) <=> (stats['Download'][x['id']] || 0) 
        result = x["title_display"] <=> y["title_display"] if result == 0
      result
    end

    if(months_list != nil)
      process_stats_by_month(stats, totals, ids, download_ids, startdate, enddate, months_list)     
    end   

    return results, stats, totals
    
  end


  def init_holders(results, startdate, enddate)
    
    ids = results.collect { |r| r['id'].to_s.strip }
    
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    
    download_ids = Hash.new { |h,k| h[k] = [] } 
    
    ids.each do |doc_id|
      download_ids[doc_id] |= fedora_server.item(doc_id).listMembers.collect(&:pid)
#      download_ids[doc_id] |=  fedora_server.item(doc_id).describedBy.collect(&:pid)
    end
    
    stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 }}
    totals = Hash.new { |h,k| h[k] = 0 }

    return stats, totals, ids, download_ids
    
  end
  
  def process_stats(stats, totals, ids, download_ids, startdate, enddate)
    
    stats['View'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", ids, startdate, enddate])

    stats_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", download_ids.values.flatten, startdate, enddate])

    download_ids.each_pair do |doc_id, downloads|
      stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
    end    
    
    stats['View'] = convertOrderedHash(stats['View'])
    
    stats['View Lifetime'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?)", ids])
    stats_lifetime_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?)" , download_ids.values.flatten])
    
    download_ids.each_pair do |doc_id, downloads|
      stats['Download Lifetime'][doc_id] = downloads.collect { |download_id| stats_lifetime_downloads[download_id] || 0 }.sum
    end
    
    stats.keys.each { |key| totals[key] = stats[key].values.sum }

    stats['View Lifetime'] = convertOrderedHash(stats['View Lifetime'])
    
  end


  def make_solar_request(author)

    if(author =~ /^\S+\d+$/)
          solr_query = "author_uni:#{author}"
        else
          solr_query = "author_facet:\"#{author}\""
        end    
    
        return Blacklight.solr.find( :per_page => 100000, 
                                     :sort => "title_display asc", 
                                     :fq => solr_query,
                                     :fl => "title_display,id,handle,doi,genre_facet", 
                                     :page => 1
                                   )["response"]["docs"]    
  end

  def make_months_list(startdate, enddate)
    months = Hash.new

    (startdate..enddate).each do |date|
      months.store(date.strftime("%Y-%m"), date.strftime("%b-%Y"))
    end
    
    return months
  end
  
end
