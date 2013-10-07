xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0", "xmlns:dc"=>"http://purl.org/dc/elements/1.1", "xmlns:cu_global"=>"http://academiccommons.columbia.edu/cu_global/1.0") {

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
        	xml.tag!("dc:creator", doc[:author_display])
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
	    if (doc[:subject_facet])
        	xml.tag!("cu_global:subject", doc[:subject_facet].join(", "))
	    end
	    if (doc[:author_uni])
        	xml.tag!("cu_global:uid", doc[:author_uni].join(", "))
	    end
	    if (doc[:department_facet])
        	xml.tag!("cu_global:department", doc[:department_facet].join(", "))
	    end
	    if (doc[:genre_facet])
        	xml.tag!("cu_global:content_type", doc[:genre_facet].join(", "))
	    end
      end
    end

  }
}