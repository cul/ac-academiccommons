class Resource < ActiveFedora::Base
  include AcademicCommons::Resource

  def to_solr(solr_doc = {}, options = {})
    super.tap do |doc|
      doc['pid'] ||= pid
      doc['fedora3_pid_ssi'] = pid

      doi = doc.fetch('doi_ssim', nil)
      doc['cul_doi_ssi'] = doi.gsub('doi:', '') if doi.present?

      doc['id'] = doc['cul_doi_ssi'] || pid

      if (content = downloadable_content)
        doc['downloadable_content_type_ssi'] = content.mimeType
        doc['downloadable_content_dsid_ssi'] = content.dsid
        doc['downloadable_content_label_ss'] = content.label.blank? ? this.label : content.label
        doc['downloadable_content_size_isi'] = size
      end

      doc['access_copy_location_ssi'] = access.dsLocation if access

      doc['dc_type_ssm'] = dc_types
      # fulltext_str = fulltext.to_s.force_encoding('utf-8').gsub(/\s+/, ' ')
      # doc['fulltext_tsi'] = fulltext_str if fulltext_str.present?
    end
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

  def access
    datastreams['access']
  end

  def dc
    datastreams['DC']
  end

  def dc_types
    return [] unless dc&.content
    content = Nokogiri::XML(dc.content.to_s)
    return [] unless content
    content.xpath('/oai_dc:dc/dc:type')&.map(&:text)
  end

  # Retrieves size stored in the RELS-INT datastream for resources.
  # Returns nil if not found.
  def size
    return unless rels_int
    content_ds = Nokogiri::XML(rels_int.content.to_s)
                         .at_xpath("rdf:RDF/rdf:Description[@rdf:about='info:fedora/#{pid}/content']")
    return unless content_ds
    size = content_ds.at_xpath('//dc:extent', dc: 'http://purl.org/dc/terms/')
    return unless size
    size.text.to_i
  end
end
