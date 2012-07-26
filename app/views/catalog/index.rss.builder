xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0", "xmlns:dc"=>"http://purl.org/dc/elements/1.1") {

  xml.channel {

    xml.title(application_name + " Search Results")
    xml.link(catalog_index_url(params))
    xml.description(application_name + " Search Results")
    xml.language('en-us')
    @document_list.each do |doc|
      xml.item do
        xml.title( doc.to_semantic_values[:title][0] || doc[:id] )
        xml.link(catalog_url(doc[:id]))
        xml.tag!("dc:author", doc[:author_display] )
	    xml.handle(doc[:handle])
	    xml.record_creation_date(doc[:record_creation_date])
      end
    end

  }
}