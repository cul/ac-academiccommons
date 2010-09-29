module CatalogHelper


  def build_recent_updated_list()
      query_params = {:q => "", :fl => "title_display, id, author_facet, author_id_uni", :sort => 'timestamp desc', :per_page => 100}
      return build_distinct_authors_list(0, query_params)
   end

  def build_distinct_authors_list(start, query_params)
      results = Hash.new{}
      updated = Blacklight.solr.find(query_params)
      updated["response"]["docs"].each do |r|
      	author = r["author_facet"]
        if(!results[author])
	   results[author] = r
	   if(results.length == 20)
   	   return results
	   end
	elsif(updated.empty?)
	   query_params.merge(:start_row => start + 100)
      	   build_distinct_authors_list(list_length, query_params)
      end
      end
  end


  def build_resource_list(document)
    obj_display = (document["object_display"] || []).first
    results = []
    case document["format"]

    when "Object"
    uri_prefix = "info:fedora/"
    hc = HTTPClient.new()
    
    fedora_url = "#{FEDORA_CONFIG[:riurl]}/get/"

    urls = {
      :members => fedora_url + document["id"] +  "/ldpd:sdef.Aggregator/listMembers?max=&format=&start=",
    }
   
    docs = {}
    urls.each_pair do |key, url|
      docs[key] = Nokogiri::XML(hc.get_content(url))
    end

    domain = "#{FEDORA_CONFIG[:riurl]}"
    user = "cdrs"
    password = "***REMOVED***"
    hc.set_auth(domain, user, password)


    members = docs[:members].css("member").to_enum(:each_with_index).collect do |member, i|
        res = {}
        member_pid = member.attributes["uri"].value.sub(uri_prefix, "")
        res[:pid] = member_pid
	res[:filename] = Nokogiri::XML(hc.get_content("#{FEDORA_CONFIG[:riurl]}/" + "objects/" + member.attributes["uri"].value.sub(uri_prefix, "") + "/objectXML")).xpath("/foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#label']/@VALUE")      
	res[:download_path] = fedora_content_path(:download, res[:pid], 'CONTENT', res[:filename])
	results << res
	end


    when "image/zooming"
      base_id = base_id_for(document)
      url = FEDORA_CONFIG[:riurl] + "/get/" + base_id + "/SOURCE"
      head_req = HTTPClient.new.head(url)
      # raise head_req.inspect
      file_size = head_req.header["Content-Length"].first.to_i
      results << {:dimensions => "Original", :mime_type => "image/jp2", :show_path => fedora_content_path("show", base_id, "SOURCE", base_id + "_source.jp2"), :download_path => fedora_content_path("download", base_id , "SOURCE", base_id + "_source.jp2")}  
    when "image"
      if obj_display
        images = doc_json_method(document, "/ldpd:sdef.Aggregator/listMembers?max=&format=json&start=&callback=?")["results"]
        images.each do |image|
          res = {}
          res[:dimensions] = image["imageWidth"] + " x " + image["imageHeight"]
          res[:mime_type] = image["type"]
          res[:file_size] = image["fileSize"].to_i
          res[:size] = (image["fileSize"].to_i / 1024).to_s + " Kb"
          
          base_id = trim_fedora_uri_to_pid(image["member"])
          base_filename = base_id.gsub(/\:/,"")
          img_filename = base_filename + "." + image["type"].gsub(/^[^\/]+\//,"")
          dc_filename = base_filename + "_dc.xml"

          res[:show_path] = fedora_content_path("show", base_id, "CONTENT", img_filename)
          res[:download_path] = fedora_content_path("download", base_id, "CONTENT", img_filename)
          res[:dc_path] = fedora_content_path('show_pretty', base_id, "DC", dc_filename)
          results << res
        end
      end 
    end
    return results
  end

  def base_id_for(doc)
    doc["id"].gsub(/(\#.+|\@.+)/, "")
  end

  def doc_object_method(doc, method)
    doc["object_display"].first + method.to_s
  end

  def doc_json_method(doc, method)
    hc = HTTPClient.new
    res = JSON.parse(hc.get_content(doc_object_method(doc,method)))

  end

  def get_metadata_list(doc)
    
    doc["object_display"] = doc["id"]
#    json = doc_json_method(doc, "/ldpd:sdef.Core/describedBy?format=json")["results"]
    hc = HTTPClient.new
    json = JSON.parse(hc.get_content("https://repository2.cul.columbia.edu:8443/fedora/objects/ac:124978/methods/ldpd:sdef.Core/describedBy?format=json"))["results"]
    json << {"DC" => base_id_for(doc)}
    results = []
    json.each do  |meta_hash|
      meta_hash.each do |desc, uri|
        res = {}
        res[:title] = desc
        res[:id] = trim_fedora_uri_to_pid(uri) 
        block = desc == "DC" ? "DC" : "CONTENT"
        filename = res[:id].gsub(/\:/,"")
        filename += "_" + res[:title].downcase
        filename += ".xml"
        res[:show_url] = fedora_content_path(:show_pretty, res[:id], block, filename)
        res[:download_url] = fedora_content_path(:download, res[:id], block, filename)
        results << res
      end
    end
    return results
  end

  def trim_fedora_uri_to_pid(uri)
    uri.gsub(/info\:fedora\//,"")
  end

  def resolve_fedora_uri(uri)
    FEDORA_CONFIG[:riurl] + "/get" + uri.gsub(/info\:fedora/,"")
  end
end
