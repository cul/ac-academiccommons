require 'cgi'
require 'rsolr'

module CatalogHelper

  include ApplicationHelper

  def auto_add_empty_spaces(text)
    text.to_s.gsub(/([^\s-]{5})([^\s-]{5})/,'\1&#x200B;\2')
  end

  def get_total_count
    query_params = {:qt=>"standard", :q=>"*:*"}
    return get_count(query_params)
  end

  def get_count_by_year
    query_params = {:qt=>"standard", :q=>"record_creation_date:[NOW-1YEAR TO NOW]"}      
    return get_count(query_params)
  end

  def get_count_by_month
    query_params = {:qt=>"standard", :q=>"record_creation_date:[NOW-1MONTH TO NOW]"}      
    return get_count(query_params)
  end

  def get_count(query_params)
    results = Blacklight.solr.find(query_params)
    return results["response"]["numFound"]
  end
  
  def custom_results()
    
    bench_start = Time.now
    
    if (!params[:id].nil?) 
      params[:id] = nil
    end
    
    params[:page] = nil
    params[:q] = (params[:q].nil?) ? "" : params[:q].to_s
    params[:sort] = (params[:sort].nil?) ? "record_creation_date desc" : params[:sort].to_s
    params[:rows] = (params[:rows].nil? || params[:rows].to_s == "") ? ((params[:id].nil?) ? Blacklight.config[:feed_rows] : params[:id].to_s) : params[:rows].to_s
    
    extra_params = {}
    extra_params[:fl] = "title_display,id,author_facet,author_display,record_creation_date,handle,abstract"

    if (params[:f].nil?) 
      solr_response = force_to_utf8(Blacklight.solr.find(params.merge(extra_params))) 
    else
      solr_response = force_to_utf8(Blacklight.solr.find(self.solr_search_params(params).merge(extra_params)))
    end

    document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc, solr_response)}  

    document_list.each do |doc|     
     doc[:pub_date] = Time.parse(doc[:record_creation_date].to_s).to_s(:rfc822)
    end
    
    logger.info("Solr fetch: #{self.class}#custom_results (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
    
    return [solr_response, document_list]
    
  end  

  def build_recent_updated_list()
    query_params = {:q => "", :fl => "title_display, id, author_facet, record_creation_date", :sort => "record_creation_date desc", :start => 0, :rows => 100}
    included_authors = []
    results = []
    return build_distinct_authors_list(query_params, included_authors, results)
  end

  def build_distinct_authors_list(query_params, included_authors, results)
    updated = Blacklight.solr.find(query_params)
    items = updated["response"]["docs"]
    if(items.empty?)
      return results
    end
    items.sort! do  |x,y|     
      y["record_creation_date"]<=>x["record_creation_date"]
    end
    items.each do |r|
      new = true
      if(r["author_facet"])
        r["author_facet"].each do |author|
          if(included_authors.include?(author))
            new = false
          else
            included_authors << author
          end
        end
        if (new)
          results << r
          if(results.length == Blacklight.config[:max_most_recent])
            return results
          end
        end
      end
    end
    if(results.length < Blacklight.config[:max_most_recent])
      query_params[:start] = query_params[:start] + 100
      build_distinct_authors_list(query_params, included_authors, results)
    else
      return results
    end
  end

  def build_resource_list(document)
   obj_display = (document["id"] || []).first
   results = []
   uri_prefix = "info:fedora/"
   hc = HTTPClient.new()
   hc.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
   fedora_url = "#{fedora_config["riurl"]}/get/"

   urls = {
      :members => fedora_url + document["id"][0] +  "/ldpd:sdef.Aggregator/listMembers?max=&format=&start=",
   }

   docs = {}
   urls.each_pair do |key, url|
       docs[key] = Nokogiri::XML(hc.get_content(url))
   end

   domain = "#{fedora_config["riurl"]}"
   user = "cdrs"
   password = "***REMOVED***"
   hc.set_auth(domain, user, password)


   members = docs[:members].css("member").to_enum(:each_with_index).collect do |member, i|

     res = {}
     member_pid = member.attributes["uri"].value.sub(uri_prefix, "")

     #this catches failed attempts to contact the fedora server 
     begin

     #get the state of the object and if not active, skip
     state = Nokogiri::XML(hc.get_content("#{fedora_config["riurl"]}/" + "objects/" + member.attributes["uri"].value.sub(uri_prefix, "") + "/objectXML")).xpath("/foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state']/@VALUE")      

     state_str = "#{state}"

     if('active'.casecmp(state_str) != 0)
       next
      end

      rescue
       next
      end      

      res[:pid] = member_pid

      begin

      res[:filename] = Nokogiri::XML(hc.get_content("#{fedora_config["riurl"]}/" + "objects/" + member.attributes["uri"].value.sub(uri_prefix, "") + "/objectXML")).xpath("/foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#label']/@VALUE")      

      rescue
       next
      end      

      res[:download_path] = fedora_content_path(:download, res[:pid], 'CONTENT', res[:filename])
      
      url = fedora_config["riurl"] + "/get/" + member_pid + "/" + 'CONTENT'

      cl = HTTPClient.new
      cl.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      h_ct = cl.head(url).header["Content-Type"].to_s
      res[:content_type] = h_ct

      results << res
    end

    return results
  end
 
  def get_departments_list
    results = []
    query_params = {:q=>"", :rows=>"0", "facet.limit"=>-1}
    solr_results = Blacklight.solr.find(query_params)
    affiliation_departments = solr_results.facet_counts["facet_fields"]["department_facet"]
    res = {}
    affiliation_departments.each do |item|
      if(item.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil)
        res[:count] = item
        results << res
        res = {}
      else
        res[:name] = item
      end
    end
    return results
  end
 
  def get_department_facet_list(department)
    results = {}
    query_params = {:q=>"", :'fq'=>"department_facet:\"" + department + "\"", :rows=>"0", "facet.limit"=>-1}
    solr_results = Blacklight.solr.find(query_params)
    facet_fields = solr_results.facet_counts["facet_fields"]
    
    facet_fields.each do |key, value|
      if(key != "department_facet" && key != "organization_facet")
        facet_field_values = []
        facet_field_value = {}
        value.each do |item|
          if(item.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil)
            facet_field_value[:count] = item
            facet_field_values << facet_field_value
            facet_field_value = {}
          else
            facet_field_value[:name] = item
          end
        end
        results[key] = facet_field_values
      end
    end
    return results
  end
  
  def get_subjects_list
    results = []
    query_params = {:q=>"", :rows=>"0", "facet.limit"=>-1, "facet.field" => "subject_facet"}
    solr_results = Blacklight.solr.find(query_params)
    subjects = solr_results.facet_counts["facet_fields"]["subject_facet"]
    res = {}
    subjects.each do |item|
      if(item.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil)
        res[:count] = item
        results << res
        res = {}
      else
        res[:name] = item
      end
    end
    return results
  end

  def thumbnail_for_resource(resource)
    extension = get_file_extension(resource[:filename].to_s)
    thumbnail_folder_path = Rails.root.to_s + "/app/assets/images/thumbnail_icons/"
    if(!extension.nil? && !extension.empty?)
      thumbnail_file_name = extension + ".png"
    else
      thumbnail_file_name = [:content_type]
      thumbnail_file_name["/"] = "_"
      thumbnail_file_name += ".png"
    end
    
    if(!File.file?(thumbnail_folder_path + thumbnail_file_name))
      thumbnail_file_name = "default.png"
    end
    
    return thumbnail_file_name
  end
  
  def get_file_extension(filename)
    filename.to_s.split(".").last.strip
  end

  def base_id_for(doc)
    doc["id"].first.gsub(/(\#.+|\@.+)/, "")
  end

  def doc_object_method(doc, method)
    doc["object_display"].first + method.to_s
  end

  def doc_json_method(doc, method)
    hc = HTTPClient.new
     hc.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    res = JSON.parse(hc.get_content(doc_object_method(doc,method)))
  end

  def get_metadata_list(doc)
#catch any error and return an error message that resources are unavailable
#this prevents fedora server outages from making ac2 item page inaccessible
begin
    hc = HTTPClient.new
    doc["object_display"] = [ "#{fedora_config["riurl"]}" + "/objects/" + doc["id"].first + "/methods" ]
    json = doc_json_method(doc, "/ldpd:sdef.Core/describedBy?format=json")["results"]
    json << {"DC" => base_id_for(doc)}
    results = []
    json.each do  |meta_hash|
      meta_hash.each do |desc, uri|
        res = {}
        res[:title] = desc
        res[:id] = trim_fedora_uri_to_pid(uri) 
          
        # TEMP -- we want to ignore DC link for now, maybe forever
        if(desc == "DC")
          next
        end  
          
        block = desc == "DC" ? "DC" : "CONTENT"
        filename = res[:id].gsub(/\:/,"")
        filename += "_" + res[:title].downcase
        filename += ".xml"
        res[:show_url] = fedora_content_path(:show_pretty, res[:id], block, filename)
        res[:download_url] = fedora_content_path(:download, res[:id], block, filename)
        results << res
      end
    end
    rescue 
      results = []
    end

    return results
  end

  def trim_fedora_uri_to_pid(uri)
    uri.gsub(/info\:fedora\//,"")
  end

  def resolve_fedora_uri(uri)
    fedora_config["riurl"] + "/get" + uri.gsub(/info\:fedora/,"")
  end
  
  ############### Copied from Blacklight CatalogHelper #####################
  
  # Pass in an RSolr::Response (or duck-typed similar) object, 
  # it translates to a Kaminari-paginatable
  # object, with the keys Kaminari views expect. 
  def paginate_params(response)
    per_page = response.rows
    per_page = 1 if per_page < 1
    current_page = (response.start / per_page).ceil + 1
    num_pages = (response.total / per_page.to_f).ceil
    Struct.new(:current_page, :num_pages, :limit_value).new(current_page, num_pages, per_page)
  end    

  # Equivalent to kaminari "paginate", but takes an RSolr::Response as first argument. 
  # Will convert it to something kaminari can deal with (using #paginate_params), and
  # then call kaminari paginate with that. Other arguments (options and block) same as
  # kaminari paginate, passed on through. 
  # will output HTML pagination controls. 
  def paginate_rsolr_response(response, options = {}, &block)
    paginate paginate_params(response), options, &block
  end

  #
  # shortcut for built-in Rails helper, "number_with_delimiter"
  #
  def format_num(num); number_with_delimiter(num) end

  #
  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message. 
  def render_pagination_info(response, options = {})
      start = response.start + 1
      per_page = response.rows
      current_page = (response.start / per_page).ceil + 1
      num_pages = (response.total / per_page.to_f).ceil
      total_hits = response.total

      start_num = format_num(start)
      end_num = format_num(start + response.docs.length - 1)
      total_num = format_num(total_hits)

      entry_name = options[:entry_name] ||
        (response.empty?? 'entry' : response.docs.first.class.name.underscore.sub('_', ' '))

      if num_pages < 2
        case response.docs.length
        when 0; "No #{h(entry_name.pluralize)} found".html_safe
        when 1; "Displaying <b>1</b> #{h(entry_name)}".html_safe
        else;   "Displaying <b>all #{total_num}</b> #{entry_name.pluralize}".html_safe
        end
      else
        "Displaying #{h(entry_name.pluralize)} <b>#{start_num} - #{end_num}</b> of <b>#{total_num}</b>".html_safe
      end
  end

  # Like  #render_pagination_info above, but for an individual
  # item show page. Displays "showing X of Y items" message. Actually takes
  # data from session though (not a great design). 
  # Code should call this method rather than interrogating session directly,
  # because implementation of where this data is stored/retrieved may change. 
  def item_page_entry_info
    "Showing item <b>#{session[:search][:counter].to_i} of #{format_num(session[:search][:total])}</b> from your search.".html_safe
  end
  
  # Look up search field user-displayable label
  # based on params[:qt] and configuration.
  def search_field_label(params)
    if(params[:search_field].blank?)
      h( "Keyword" )
    else
      h( Blacklight.label_for_search_field(params[:search_field]) )
    end    
  end

  # Export to Refworks URL, called in _show_tools
  def refworks_export_url(document = @document)
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(catalog_path(document.id, :format => 'refworks_marc_txt', :only_path => false))}"        
  end
  
  def render_document_class(document = @document)
   'blacklight-' + document.get(Blacklight.config[:index][:record_display_type]).parameterize rescue nil
  end

  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
  end
  
  def pdf_urls
    urls = []
    if(@document != nil)
      
      resource_list = build_resource_list(@document)
      resource_list.each do |resource|    
           urls.push( "http://" + request.host_with_port + resource[:download_path] ) 
       end
     end  
     return urls
  end  
  

  def related_links
    
      cu_department = @document['originator_department'][0]
      
      rsolr = RSolr.connect :url => Rails.application.config.related_content_solr_url
      search = rsolr.select :params => { :q => 'cu_department:"' + cu_department + '"', :qt => "document", :start => 0, :rows => 5, :sort => "date_ssued desc"}
    
      search = search["response"]
      search = search["docs"]
      
      return search

  end

end