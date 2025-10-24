# frozen_string_literal: true

module AcademicCommons::GenericResource
  extend ActiveSupport::Concern

  included do
    include AcademicCommons::Resource
  end

  def to_solr(solr_doc = {}, options = {})
    super.tap do |doc|
      doc['pid'] ||= self.pid
      doc['fedora3_pid_ssi'] = self.pid
      doi = Array(doc.fetch('doi_ssim', nil)).first
      raise StandardError, 'missing doi from fedora object' if doi.blank?
      doc['cul_doi_ssi'] = doi.sub('doi:', '')

      # Fedora returns a hash with :id=>pid -- we overwrite this value with the DOI before sending to Solr for indexing
      doc[:id] = doc['cul_doi_ssi']

      add_downloadable_content_solr_fields(doc)

      doc['access_copy_location_ssi'] = access&.dsLocation

      doc['dc_type_ssm'] = dc_types
      doc['datastreams_ssim'] = datastreams.keys.map(&:to_s)
    end
  end

  def downloadable_content
    datastreams['content'] || datastreams['CONTENT']
  end

  def add_downloadable_content_solr_fields(doc)
    downloadable_content&.tap do |content|
      doc['downloadable_content_type_ssi'] = content.mimeType
      doc['downloadable_content_dsid_ssi'] = content.dsid
      doc['downloadable_content_label_ss'] = content.label.blank? ? this.label : content.label
      doc['downloadable_content_size_isi'] = size
    end
  end

  # Return string with fulltext or nil if there isn't a datastream to pull from
  def fulltext
    datastreams['fulltext']&.content
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
