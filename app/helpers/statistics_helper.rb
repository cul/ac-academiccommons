require 'csv'

module StatisticsHelper
  
  include CatalogHelper
  
  VIEW = 'view_'
  DOWNLOAD = 'download_'
  LINE_BRAKER = RUBY_VERSION < "1.9" ? "\r\n" : ""
   
  def cvsReport(startdate, enddate, author, include_zeroes, recent_first, facet)

    months_list = make_months_list(startdate, enddate, recent_first)
    results, stats, totals, download_ids = get_author_stats(startdate, enddate, author, months_list, include_zeroes, facet)

    csv = "Author UNI/Name: ," + author.to_s + LINE_BRAKER
 
    csv += CSV.generate_line( [ "Period covered by Report" ]) + LINE_BRAKER
    csv += CSV.generate_line( [ "from:", "to:" ]) + LINE_BRAKER
    csv += CSV.generate_line( [ startdate.strftime("%b-%Y"),  enddate.strftime("%b-%Y") ]) + LINE_BRAKER
    csv += CSV.generate_line( [ "Date run:" ]) + LINE_BRAKER
    csv += CSV.generate_line( [ Time.new.strftime("%Y-%m-%d") ] ) + LINE_BRAKER
    csv += CSV.generate_line( [ "Report created by:" ]) + LINE_BRAKER
    csv += CSV.generate_line( [  current_user == nil ? "N/A" : (current_user.to_s + " (" + current_user.login.to_s + ")") ]) + LINE_BRAKER
    

    csv = makeCSVcategory("Views", "View", csv, results, stats, totals, months_list, download_ids)
    csv = makeCSVcategory("Streams", "Streaming", csv, results, stats, totals, months_list, download_ids)
    csv = makeCSVcategory("Downloads", "Download", csv, results, stats, totals, months_list, download_ids)

    return csv
  end
  
  
  
  def makeCSVcategory(category, key, csv, results, stats, totals, months_list, download_ids)
    
    csv += CSV.generate_line( [ "" ]) + LINE_BRAKER
    
    csv += CSV.generate_line( [ category + " report:" ]) + LINE_BRAKER
    
        csv += CSV.generate_line( [ "Total for period:", 
                                "",
                                "",
                                "", 
                                totals["Download"].to_s
                               ].concat(make_months_header(category + " by Month", months_list))
                             ) + LINE_BRAKER
                            
    csv += CSV.generate_line( [ "Title", 
                                "Content Type", 
                                "Permanent URL",
                                "DOI", 
                                "Reporting Period Total " + category
                               ].concat( make_month_line(months_list))   
                             ) + LINE_BRAKER

    results.each do |item|

    csv += CSV.generate_line([item["title_display"],
                              item["genre_facet"],
                              item["handle"],
                              item["doi"],
                              stats[key][item["id"][0]].nil? ? 0 : stats[key][item["id"][0]]
                              ].concat( make_month_line_stats(stats, months_list, item["id"][0], download_ids))
                              ) + LINE_BRAKER  
    end
    
    return csv
    
  end
  
  
  
  def make_months_header(first_item, months_list)
    
    header = []

    header << first_item

    months_list.size.downto(2) do
      header << ""
    end 

    return header
  end

  def make_month_line(months_list)
    
    month_list = []
    
    months_list.each do |month|
      month_list << month.strftime("%b-%Y")
    end
    
    return month_list
  end

  def make_month_line_stats(stats, months_list, id, download_ids)
    
    line = []
    
    months_list.each do |month|                   
      
      if(download_ids != nil)    
        download_id = download_ids[id]       
        line << (stats[DOWNLOAD + month.to_s][download_id.to_s].nil? ? 0 : stats[DOWNLOAD + month.to_s][download_id.to_s])
      else
        line << (stats[VIEW + month.to_s][id].nil? ? 0 : stats[VIEW + month.to_s][id])
      end
      
    end      
    return line
  end


  def process_stats_by_month(stats, totals, ids, download_ids, startdate, enddate, months_list)
    
    months_list.each do |month|
      
      contdition = month.strftime("%Y-%m") + "%"

      stats[VIEW + month.to_s] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) and at_time like ?", ids, contdition])
      stats[DOWNLOAD + month.to_s] = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) and at_time like ?", download_ids.values.flatten, contdition])

    end

  end

  

  def get_author_stats(startdate, enddate, query, months_list, include_zeroes, facet)

    results = make_solar_request(facet, query)

    stats, totals, ids, download_ids = init_holders(results)

    process_stats(stats, totals, ids, download_ids, startdate, enddate)
    
      results.reject! { |r| (stats['View'][r['id'][0]] || 0) == 0 &&  (stats['Download'][r['id']] || 0) == 0 } unless include_zeroes
        
      results.sort! do |x,y|
        result = (stats['Download'][y['id']] || 0) <=> (stats['Download'][x['id']] || 0) 
        if(facet != "search") 
          result = x["title_display"] <=> y["title_display"] if result == 0
        end  
      result
    end

    if(months_list != nil)
      process_stats_by_month(stats, totals, ids, download_ids, startdate, enddate, months_list)     
    end   

    return results, stats, totals, download_ids
    
  end


  def init_holders(results)
    
    ids = results.collect { |r| r['id'].to_s.strip }
    
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    
    download_ids = Hash.new { |h,k| h[k] = [] } 
    
    ids.each do |doc_id|
      download_ids[doc_id] |= fedora_server.item(doc_id).listMembers.collect(&:pid)
    end
    
    stats = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 }}
    totals = Hash.new { |h,k| h[k] = 0 }

    return stats, totals, ids, download_ids
    
  end
  
  
  def process_stats(stats, totals, ids, download_ids, startdate, enddate)
    
    enddate = enddate + 1.months
    
    stats['View'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) AND at_time BETWEEN ? and ?", ids, startdate, enddate])
    stats['Streaming'] = Statistic.count(:group => "identifier", :conditions => ["event = 'Streaming' and identifier IN (?) AND at_time BETWEEN ? and ?", ids, startdate, enddate])

    stats_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) AND at_time BETWEEN ? and ?", download_ids.values.flatten, startdate, enddate])

    download_ids.each_pair do |doc_id, downloads|
      stats['Download'][doc_id] = downloads.collect { |download_id| stats_downloads[download_id] || 0 }.sum
    end    
    
    stats['View'] = convertOrderedHash(stats['View'])
    
    stats['View Lifetime'] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?)", ids])
    stats['Streaming Lifetime'] = Statistic.count(:group => "identifier", :conditions => ["event = 'streaming' and identifier IN (?)", ids])
    
    stats_lifetime_downloads = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?)" , download_ids.values.flatten])
    
    download_ids.each_pair do |doc_id, downloads|
      stats['Download Lifetime'][doc_id] = downloads.collect { |download_id| stats_lifetime_downloads[download_id] || 0 }.sum
    end
    
    stats.keys.each { |key| totals[key] = stats[key].values.sum }

    stats['View Lifetime'] = convertOrderedHash(stats['View Lifetime'])
    
  end


  def make_solar_request(facet, query)

    if(facet == "search")
      facet_query = ""
      q = query
      sort = "record_creation_date desc"
    else
      facet_query = "#{facet}:\"#{query}\""
      sort = "title_display asc"
    end

    return Blacklight.solr.find( :per_page => 100000, 
                                 :sort => sort, 
                                 :q => q,
                                 :fq => facet_query,
                                 :fl => "title_display,id,handle,doi,genre_facet", 
                                 :page => 1
                                )["response"]["docs"]    
  end
  
  
  def make_months_list(startdate, enddate, recent_first)
    months = []
    months_hash = Hash.new
    
    (startdate..enddate).each do |date|
      
      key = date.strftime("%Y-%m")
      
      if(!months_hash.has_key?(key))
        months << date
        months_hash.store(key, "")
      end    
    end    
    
    if(recent_first)
      return months.reverse
    else
      return months
    end
  end
  
end
