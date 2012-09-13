xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0", "xmlns:dc"=>"http://purl.org/dc/elements/1.1") {

  xml.channel {

    xml.title(application_name + " Search Results")
    xml.link(catalog_index_url(params))
    xml.description(application_name + " Search Results")
    xml.language('en-us')
    @document_list.each do |doc|
      xml.item do
        if(doc.to_semantic_values[:title][0] || doc[:id])
        	xml.title( doc.to_semantic_values[:title][0] || doc[:id] )
        end
        if(doc[:id])
        	xml.link(catalog_url(doc[:id]))
        end
        if(doc[:author_display])
        	xml.tag!("dc:creator", doc[:author_display] )
        end
	    if(doc[:handle])
	    	xml.guid(doc[:handle])
	    end
	    if (doc[:pub_date])
	    	xml.pubDate(doc[:pub_date])
	    end
	    if (doc[:abstract])
	    	xml.description(doc[:abstract])
	    end
      end
    end

  }
}