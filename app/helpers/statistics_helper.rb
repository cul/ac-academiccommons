require 'csv'

module StatisticsHelper
  
  include CatalogHelper
  require 'uri'
  
  VIEW = 'view_'
  DOWNLOAD = 'download_'
  LINE_BRAKER = RUBY_VERSION < "1.9" ? "\r\n" : ""
  
  VIEW_EVENT = 'View'
  DOWNLOAD_EVENT = 'Download'
  STREAM_EVENT = 'Streaming'
  
  FACET_NAMES = Hash.new
  FACET_NAMES.store('author_facet', 'Author')
  FACET_NAMES.store('pub_date_facet', 'Date')
  FACET_NAMES.store('genre_facet', 'Content Type')
  FACET_NAMES.store('subject_facet', 'Subject')
  FACET_NAMES.store('type_of_resource_facet', 'Resource Type')
  FACET_NAMES.store('media_type_facet', 'Media Type')
  FACET_NAMES.store('organization_facet', 'Organization')
  FACET_NAMES.store('department_facet', 'Department')
  FACET_NAMES.store('series_facet', 'Series')
  FACET_NAMES.store('non_cu_series_facet', 'Non CU Series')
  
  def facet_names
    return FACET_NAMES
  end

  def cvsReport(startdate, enddate, search_criteria, include_zeroes, recent_first, facet, include_streaming_views, order_by)

    months_list = make_months_list(startdate, enddate, recent_first)
    results, stats, totals, download_ids = get_author_stats(startdate, enddate, search_criteria, months_list, include_zeroes, facet, include_streaming_views, order_by)
    
    if (results == nil || results.size == 0)    
      setMessageAndVariables 
      return
    end

    if facet.in?('author_facet', 'author_uni')
      csv = "Author UNI/Name: ," + search_criteria.to_s + LINE_BRAKER
    else
      csv = "Search criteria: ," + search_criteria.to_s + LINE_BRAKER
    end
 
    csv += CSV.generate_line( [ "Period covered by Report" ]) + LINE_BRAKER
    csv += CSV.generate_line( [ "from:", "to:" ]) + LINE_BRAKER
    csv += CSV.generate_line( [ startdate.strftime("%b-%Y"),  enddate.strftime("%b-%Y") ]) + LINE_BRAKER
    csv += CSV.generate_line( [ "Date run:" ]) + LINE_BRAKER
    csv += CSV.generate_line( [ Time.new.strftime("%Y-%m-%d") ] ) + LINE_BRAKER
    csv += CSV.generate_line( [ "Report created by:" ]) + LINE_BRAKER
    csv += CSV.generate_line( [  current_user == nil ? "N/A" : (current_user.to_s + " (" + current_user.login.to_s + ")") ]) + LINE_BRAKER
    

    csv = makeCSVcategory("Views", "View", csv, results, stats, totals, months_list, nil)
    if(include_streaming_views)
      csv = makeCSVcategory("Streams", "Streaming", csv, results, stats, totals, months_list, nil)
    end  
    csv = makeCSVcategory("Downloads", "Download", csv, results, stats, totals, months_list, download_ids)

    return csv
  end
  
  
  
  def makeCSVcategory(category, key, csv, results, stats, totals, months_list, ids)
    
    csv += CSV.generate_line( [ "" ]) + LINE_BRAKER
    
    csv += CSV.generate_line( [ category + " report:" ]) + LINE_BRAKER
    
        csv += CSV.generate_line( [ "Total for period:", 
                                "",
                                "",
                                "", 
                                totals[key].to_s
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
                              item["genre_facet"].first,
                              item["handle"],
                              item["doi"],
                              stats[key][item["id"]].nil? ? 0 : stats[key][item["id"]]
                              ].concat( make_month_line_stats(stats, months_list, item["id"], ids))
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
  
  def months
    months = Array.new(Date::ABBR_MONTHNAMES)
    months.shift
    return months
  end

  def make_month_line(months_list)
    
    month_list = []
    
    months_list.each do |month|
      month_list << month_str = month.strftime("%b-%Y")
    end
    
    return month_list
  end

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


  def process_stats_by_month(stats, totals, ids, download_ids, startdate, enddate, months_list)
    
    months_list.each do |month|
      
      contdition = month.strftime("%Y-%m") + "%"

      stats[VIEW + month.to_s] = Statistic.count(:group => "identifier", :conditions => ["event = 'View' and identifier IN (?) and at_time like ?", ids, contdition])
      stats[DOWNLOAD + month.to_s] = Statistic.count(:group => "identifier", :conditions => ["event = 'Download' and identifier IN (?) and at_time like ?", download_ids.values.flatten, contdition])

    end

  end

  

  def get_author_stats(startdate, enddate, query, months_list, include_zeroes, facet, include_streaming_views, order_by)
    
    if(query == nil || query.empty?)
      return
    end  

    results = make_solar_request(facet, query)
    
    if results == nil
      return
    end

    stats, totals, ids, download_ids = init_holders(results)

    process_stats(stats, totals, ids, download_ids, startdate, enddate)
    
      results.reject! { |r| (stats['View'][r['id'][0]] || 0) == 0 &&  (stats['Download'][r['id']] || 0) == 0 } unless include_zeroes
        

      if(order_by == 'views' || order_by == 'downloads') 
        results.sort! do |x,y|
          if(order_by == 'downloads') 
            result = (stats['Download'][y['id']] || 0) <=> (stats['Download'][x['id']] || 0) 
          end  
          if(order_by == 'views') 
              result = (stats['View'][y['id']] || 0) <=> (stats['View'][x['id']] || 0) 
          end         
            result
        end
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
  
  
  def parse_search_query(search_query)
    
    search_query = URI.unescape(search_query)
    search_query = search_query.gsub(/\+/, ' ')
    
    params = Hash.new
    
    if search_query.include? '?'
      search_query = search_query[search_query.index("?") + 1, search_query.length]
    end

    search_query.split('&').each do |value|

      key_value = value.split('=') 

      if(key_value[0].start_with?("f[") )

        if(params.has_key?("f"))
          array = params["f"]
        else
          array = Array.new 
        end

        value = key_value[0].gsub(/f\[/, '').gsub(/\]\[\]/, '') + ":\"" + key_value[1] + "\""
        array.push(value)
        params.store("f", array)

      else 
        params.store(key_value[0], key_value[1])
      end
    end
    
    return params  
  end


  def make_solar_request(facet, query)

    if(facet == "search_query")
      
      params = parse_search_query(query)
      facet_query = params["f"]
      q = params["q"]
      sort = params["sort"]

    else
      
      facet_query = "#{facet}:\"#{query}\""
      sort = "title_display asc"
      
    end
    
    if facet_query == nil && q == nil
      return
    else  
      results = Blacklight.solr.find( :per_page => 100000, 
                                   :sort => sort, 
                                   :q => q,
                                   :fq => facet_query,
                                   :fl => "title_display,id,handle,doi,genre_facet", 
                                   :page => 1
                                  )["response"]["docs"]                           
      return results  
                            
    end                            
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
  
  def base_url
    return "http://" + Rails.application.config.base_path + Rails.application.config.relative_root
  end
  
  def setMessageAndVariables 
    @results = nil
    @stats = nil
    @totals = nil
    if (params[:facet] != "text")
      @message = "first_message"
      params[:facet] = "text"
    else
      @message = "second_message"
      params[:facet] = "text"
    end    
  end  
  
  def logStatisticsUsage(startdate, enddate, params)
    
      eventlog = Eventlog.create(:event_name => 'statistics', 
                                 :user_name  => current_user == nil ? "N/A" : current_user.to_s, 
                                 :uid        => current_user == nil ? "N/A" : current_user.login.to_s, 
                                 :ip         => request.remote_ip, 
                                 :session_id => request.session_options[:id])    
        
      eventlog.logvalues.create(:param_name => "startdate", :value => startdate.to_s) 
      eventlog.logvalues.create(:param_name => "enddate", :value => enddate.to_s)
      eventlog.logvalues.create(:param_name => "commit", :value => params[:commit])
      eventlog.logvalues.create(:param_name => "search_criteria", :value => params[:search_criteria] )
      eventlog.logvalues.create(:param_name => "include_zeroes", :value => params[:include_zeroes] == nil ? "false" : "true")
      eventlog.logvalues.create(:param_name => "include_streaming_views", :value => params[:include_streaming_views] == nil ? "false" : "true")
      eventlog.logvalues.create(:param_name => "facet", :value => params[:facet])
      eventlog.logvalues.create(:param_name => "email_to", :value => params[:email_destination] == "email to" ? nil : params[:email_destination])
    
  end
  
  def setDefaultParams(params)
    
     if (params[:month_from].nil? || params[:month_to].nil? || params[:year_from].nil? || params[:year_to].nil?)
      
      params[:month_from] = "Apr"
      params[:year_from] = "2011"
      params[:month_to] = (Date.today - 1.months).strftime("%b")
      params[:year_to] = (Date.today).strftime("%Y")
      
      params[:include_zeroes] = true
      
    end     
  end
  

  def makeTestAuthor(author_id, email)  

        test_author = Hash.new
        test_author[:id] = author_id
        test_author[:email] = email     
           
        processed_authors = Array.new 
        processed_authors.push(test_author)
        return processed_authors
  end      
  
  
  def sendReport(recepient, author_id, startdate, enddate, results, stats, totals, request, include_streaming_views, optional_note)
    case params[:email_template]
    when "Normal"
      Notifier.author_monthly(recepient, author_id, startdate, enddate, results, stats, totals, request, include_streaming_views, optional_note).deliver
    else
      Notifier.author_monthly_first(recepient, author_id, startdate, enddate, results, stats, totals, request, include_streaming_views).deliver
    end
  end
  
  def downloadCSVreport(startdate, enddate, params)
        logStatisticsUsage(startdate, enddate, params)
        
        csv_report = cvsReport( startdate,
                                enddate,
                                params[:search_criteria],
                                params[:include_zeroes],
                                params[:recent_first],
                                params[:facet],
                                params[:include_streaming_views],
                                params[:order_by]
                               )
                               
         if(csv_report != nil)
           send_data csv_report, :type=>"application/csv", :filename=>params[:search_criteria] + "_monthly_statistics.csv" 
         end 
  end
  
  def school_pids(school)
    
    pids_by_institution = Blacklight.solr.find(
                          :qt=>"search", 
                          :rows=>20000,
                          :fq=>["{!raw f=organization_facet}" + school], 
                          :"facet.field"=>["pid"], 
                          )["response"]["docs"] 
                          
    return pids_by_institution                       
                          
  end

  def get_school_docs_size(school)
    query_params = {:qt=>"standard", :q=>'{!raw f=organization_facet}' + school}
    return get_count(query_params)
  end
  
  # @@facets_list = Hash.new  
  # def facet_items(facet)
#     
    # if(!@@facets_list.has_key?(facet) )
      # @@facets_list.store(facet, make_facet_items(facet))
      # logger.info("======= fasets init ====== ")
    # end  
# 
    # return @@facets_list[facet]
  # end
  # def make_facet_items(facet)
  def facet_items(facet)
    
    results = []
    query_params = {:q=>"", :rows=>"0", "facet.limit"=>-1, :"facet.field"=>[facet]}
    solr_results = Blacklight.solr.find(query_params)
    subjects = solr_results.facet_counts["facet_fields"][facet]
    
    results << ["" ,""]
    
    res_item = {}
    subjects.each do |item|

      if(item.kind_of? Integer)
        res_item[:count] = item
        
        #Rails.logger.debug("======= " +  res_item[:count].to_s + " == " + res_item[:name].to_s)
        
        results << [res_item[:name].to_s + " (" + res_item[:count].to_s  + ")", res_item[:name].to_s]
        res_item = {}
      else
        res_item[:name] = item
      end
      
    end  
    
    return results
  end
  
  
  def getPidsByQueryFacets(query)

    solr_facets_query = Array.new
    query.each do | param|
      Rails.logger.debug(" facet parameters:  facet - " + param[0].to_s + ", facet item - " + param[1].first.to_s )
      if(param[1][0] != nil && !param[1][0].to_s.empty? && param[1][0].to_s != 'undefined' )
        solr_facets_query.push("{!raw f=" + param[0].to_s + "}" + param[1][0].to_s)
      end
    end
    
    Rails.logger.debug(" solr_facets_query size:  " + solr_facets_query.size.to_s )
    
    query_params = Hash.new 
    query_params.store("qt", "search")
    query_params.store("rows", 20000)

    
    query_params.store("fq", solr_facets_query)
    query_params.store("facet.field", ["pid"])

    return  Blacklight.solr.find(query_params)["response"]["docs"] 
  end
 
  
  def countPidsStatistic(pids_collection, event)
    count = Statistic.count(:conditions => ["identifier in (?) and event = ?", correct_pids(pids_collection, event), event]) 
    return count
  end  
 
 
  def countPidsStatisticByDates(pids_collection, event, startdate, enddate)
    count = Statistic.count(:conditions => ["identifier in (?) and event = ? and at_time BETWEEN ? and ?", correct_pids(pids_collection, event), event, startdate, enddate]) 
    return count
  end  
  
  def countDocsByEvent(pids_collection, event)
    count = Statistic.count(:conditions => ["identifier in (?) and event = ? ", correct_pids(pids_collection, event), event], :group => 'identifier') 
    return count
  end  
 
 
  def countDocsByEventAndDates(pids_collection, event, startdate, enddate)
    count = Statistic.count(:conditions => ["identifier in (?) and event = ? and at_time BETWEEN ? and ? ", correct_pids(pids_collection, event), event, startdate, enddate], :group => 'identifier') 
    return count
  end    
  


  def correct_pids(pids_collection, event)
    pids = []
    pids_collection.each do |pid|

      if(event == DOWNLOAD_EVENT)
        pids.push(pid[:id][0, 3] + (pid[:id][3, 8].to_i + 1).to_s)
      else
         pids.push(pid[:id])
      end    
   
    end
    return pids
  end
  

  def get_res_list()

    query = params[:f]

    if( query == nil || query.empty? )
      return []
    end
    
    docs = getPidsByQueryFacets(query)
    
    results = Array.new
    
    docs.each do |doc|
      
      item =  Hash.new
      
      if(params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to] )
       
        startdate = Date.parse(params[:month_from] + " " + params[:year_from])
        enddate = Date.parse(params[:month_to] + " " + params[:year_to])
        
        item.store('views', countPidsStatisticByDates([doc], VIEW_EVENT, startdate, enddate))
        item.store('downloads', countPidsStatisticByDates([doc], DOWNLOAD_EVENT, startdate, enddate))
        item.store('streams', countPidsStatisticByDates([doc], STREAM_EVENT, startdate, enddate))
        item.store('doc', doc)
        
        results << item
      else  
        
        item.store('views', countPidsStatistic([doc], VIEW_EVENT))
        item.store('downloads', countPidsStatistic([doc], DOWNLOAD_EVENT))
        item.store('streams', countPidsStatistic([doc], STREAM_EVENT))
        item.store('doc', doc)
        results << item
      end      
    end
    
    return results
  end
  
  def get_docs_size_by_query_facets()
    query = params[:f]
    
    if( query == nil || query.empty? )
      pids = []
    else  
      pids = getPidsByQueryFacets(query)
    end
    
    return pids
  end
  
  def get_time_period
    
    if(params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to] )
       
      startdate = Date.parse(params[:month_from] + " " + params[:year_from])
      enddate = Date.parse(params[:month_to] + " " + params[:year_to])
      
      time_period = startdate.strftime("%b %Y") + ' - ' + enddate.strftime("%b %Y")
    else
      time_period = 'Lifetime'  
    end    
    
    return time_period
  end
  
  def create_common_statistics_csv(get_res_list)
    
    count = 0
    csv = ''
    
    csv += CSV.generate_line( [ 'time period: ', get_time_period, '', '', '', '', '', '' ]) + LINE_BRAKER
    csv += CSV.generate_line( [ '', '', '', '', '', '', '', '']) + LINE_BRAKER
    
    query = params[:f]
    views = get_facetStatsByEvent(query, VIEW_EVENT)
    downloads = get_facetStatsByEvent(query, DOWNLOAD_EVENT)
    streams = get_facetStatsByEvent(query, STREAM_EVENT)
    
    csv += CSV.generate_line( [ 'FACET', 'ITEM', '', '', '', '', '', '']) + LINE_BRAKER
    query.each do |key, value| 
        csv += CSV.generate_line( [ facet_names[key.to_s], value.first.to_s, '', '', '', '', '', '']) + LINE_BRAKER
    end
    csv += CSV.generate_line( [ '', '', '', '', '', '', '', '' ]) + LINE_BRAKER
    
    csv += CSV.generate_line( [ get_res_list.size.to_s, '', '', '', views, downloads, streams, '', '' ]) + LINE_BRAKER
    csv += CSV.generate_line( [ '#', 'TITLE', 'GENRE', 'VIEWS', 'DOWNLOADS', 'STREAMS', 'CREATION DATE', 'URL' ]) + LINE_BRAKER
    
    get_res_list.each do |item|
      
      count = count + 1
      
      csv += CSV.generate_line( [ 
                                  count,
                                  item['doc']['title_display'],
                                  item['doc']['genre_facet'].first,
                                  item['views'],
                                  item['downloads'],
                                  item['streams'],
                                  Date.strptime(item['doc']['record_creation_date']).strftime('%m/%d/%Y'),
                                  item['doc']['handle']
                                ]) + LINE_BRAKER
    end
    
    return csv
  end
  
  def get_facetStatsByEvent(query, event)
    
    if( query == nil || query.empty? )
        downloads = 0 
        docs = Hash.new
    else  
      
      pids_collection = getPidsByQueryFacets(query)
      
      if(params[:month_from] && params[:year_from] && params[:month_to] && params[:year_to] )
        startdate = Date.parse(params[:month_from] + " " + params[:year_from])
        enddate = Date.parse(params[:month_to] + " " + params[:year_to])
        count = countPidsStatisticByDates(pids_collection, event, startdate, enddate)
        docs = countDocsByEventAndDates(pids_collection, event, startdate, enddate)
      else  
        count = countPidsStatistic(pids_collection, event) 
        docs = countDocsByEvent(pids_collection, event)
      end

    end
    
    result = docs.size.to_s + ' ( ' + count.to_s + ' )'
    return result   
  end
  

end # ------------------------------------------ #
