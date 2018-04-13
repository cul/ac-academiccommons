class Resource < ActiveFedora::Base
  include AcademicCommons::Resource

  def to_solr(solr_doc={}, options={})
    solr_doc = super
    solr_doc['pid'] ||= self.pid
    content = downloadable_content

    if content
      solr_doc['downloadable_content_type_ssi'] = content.mimeType
      solr_doc['downloadable_content_dsid_ssi'] = content.dsid
      solr_doc['downloadable_content_label_ss'] = content.label.blank? ? this.label : content.label
      solr_doc['downloadable_content_size_isi'] = size
    end

    solr_doc['fulltext_tsi'] = fulltext.to_s.force_encoding('utf-8').gsub(/\s+/, ' ')
    solr_doc
  end

  def downloadable_content
    return datastreams['content'] if (datastreams.has_key?('content'))
    return datastreams['CONTENT'] if (datastreams.has_key?('CONTENT'))
    return nil
  end

  # Return string with fulltext or nil if there isn't a datastream to pull from
  def fulltext
    datastreams.has_key?('fulltext') ? datastreams['fulltext'].content : nil
  end

  def rels_int
    datastreams['RELS-INT']
  end

  # Retrieves size stored in the RELS-INT datastream for resources.
  # Returns nil if not found.
  def size
    return unless rels_int
    content_ds = Nokogiri::XML(rels_int.content.body)
                         .at_xpath("rdf:RDF/rdf:Description[@rdf:about='info:fedora/#{pid}/content']")
    return unless content_ds
    size = content_ds.at_xpath('//dc:extent', dc: 'http://purl.org/dc/terms/')
    return unless size
    size.text.to_i
  end
end
