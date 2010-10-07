module CatalogHelper

  def get_total_count
    query_params = {:qt=>"standard", :q=>"timestamp:[* TO NOW]"}
    return get_count(query_params)
  end

  def get_count_by_year
    query_params = {:qt=>"standard", :q=>"timestamp:[NOW-1YEAR TO NOW]"}      
    return get_count(query_params)
  end

  def get_count_by_month
    query_params = {:qt=>"standard", :q=>"timestamp:[NOW-1MONTH TO NOW]"}      
    return get_count(query_params)
  end

  def get_count(query_params)
    results = Blacklight.solr.find(query_params)
    return results["response"]["numFound"]
  end

  def build_recent_updated_list()
    query_params = {:q => "", :fl => "title_display, id,  authors_display, author_id_uni, timestamp", :sort => "timestamp desc", :per_page => 100, :start => 0}
    unis = []
    results = []
    return build_distinct_authors_list(0, query_params, unis, results)
  end

  def build_distinct_authors_list(start, query_params, unis, results)
    updated = Blacklight.solr.find(query_params)
    items = updated["response"]["docs"]
    if(items.empty?)
      return results
    end
    items.sort! do  |x,y|     
      y["timestamp"]<=>x["timestamp"]
    end
    items.each do |r|
      new = true
      if(r["author_id_uni"])
        r["author_id_uni"].each do |uni|
          if(unis.include?(uni))
            new = false
          else
            unis << uni
          end
        end
        if (new)
          results << r
          if(results.length == 20)
            return results
          end
        end
      end
    end
    if(results.length < 20)
      new_start = start + 100
      query_params[:start] = new_start
      build_distinct_authors_list(new_start, query_params, unis, results)
    end
  end



  def build_resource_list(document)
    obj_display = (document["id"] || []).first
    results = []
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

    hc = HTTPClient.new
    doc["object_display"] = [ "#{FEDORA_CONFIG[:riurl]}" + "/objects/" + doc["id"] + "/methods" ]
    json = doc_json_method(doc, "/ldpd:sdef.Core/describedBy?format=json")["results"]
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
