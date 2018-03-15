class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument
  include AcademicCommons::Embargoes

  # self.unique_key = 'id'
  self.timestamp_key = 'record_creation_date'


  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  field_semantics.merge!(
    title: 'title_display',
    author: 'author_facet',
	  creator: 'author_facet',
		date: 'pub_date_facet',
    type: ['type_of_resource_facet', 'genre_facet'],
		publisher: 'publisher',
		subject: 'subject_facet',
	  description: 'abstract',
	  language: 'language'
  )

  def embargoed?
    !free_to_read?(self)
  end

  def restricted?
    has?(:restriction_on_access_ss)
  end

  def access_restriction
    fetch(:restriction_on_access_ss)
  end

  # Overriding Blacklight v5.19.2 implementation of to_semantic_values to accept
  # an array of solr fields instead of a singular solr field.
  #
  # This code was taken from Blacklight v6.11.1. When updating to Blacklight this
  # code should be removed.
  def to_semantic_values
    @semantic_value_hash ||= self.class.field_semantics.each_with_object(Hash.new([])) do |(key, field_names), hash|
      ##
      # Handles single string field_name or an array of field_names
      value = Array.wrap(field_names).map { |field_name| self[field_name] }.flatten.compact

      # Make single and multi-values all arrays, so clients
      # don't have to know.
      hash[key] = value unless value.empty?
    end

    @semantic_value_hash ||= {}

    # Custom values.
    @semantic_value_hash[:identifier] = full_doi

    @semantic_value_hash
  end

  def full_doi
    AcademicCommons.identifier_url(fetch(:handle, nil))
  end

  def assets(include_inactive: false)
    return [] unless free_to_read?(self)
    obj_display = fetch('id', [])

    member_search = {
      q: '*:*',
      qt: 'standard',
      fl: '*',
      fq: ["cul_member_of_ssim:\"info:fedora/#{obj_display}\""],
      rows: 10_000,
      facet: false
    }
    member_search[:fq] << 'object_state_ssi:A' unless include_inactive
    response = Blacklight.default_index.connection.get 'select', params: member_search
    docs = response['response']['docs']
    docs.map { |member| SolrDocument.new(member) }
  rescue StandardError => e
    Rails.logger.error e.message
    return []
  end

  def thumbnail
    return nil unless asset?
    "https://derivativo-#{rand(1..4)}.library.columbia.edu/iiif/2/#{fetch(:id)}/full/!256,256/0/native.jpg"
  end

  def filename
    return nil unless asset?
    fetch('downloadable_content_label_ss', nil)
  end

  def download_path
    return nil unless asset?
    Rails.application.routes.url_helpers.fedora_content_path(
      :download, id,
      fetch('downloadable_content_dsid_ssi'),
      fetch('downloadable_content_label_ss')
    )
  end

  def asset?
    ['GenericResource', 'Resource'].include?(fetch(:active_fedora_model_ssi, nil))
  end

  def pages
    fields = [fetch('start_page', nil), fetch('end_page', nil)].compact
    (fields.blank?) ? nil : fields.join(' - ')
  end

  def degree
    fields = [fetch('degree_name_ssim', nil), fetch('degree_grantor_ssim', nil)].compact
    (fields.blank?) ? nil : fields.join(', ')
  end
end
