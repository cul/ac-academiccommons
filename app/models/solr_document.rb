require 'academic_commons'
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument
  include AcademicCommons::Embargoes

  self.unique_key = 'cul_doi_ssi'
  self.timestamp_key = 'record_creation_dtsi'


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

  # Normalized field names
  field_semantics.merge!(
    title: 'title_ssi',
    author: 'author_ssim',
    creator: 'author_ssim',
    date: 'pub_date_isi',
    type: 'genre_ssim',
    publisher: 'publisher_ssi',
    subject: 'subject_ssim',
    description: 'abstract_ssi',
    language: 'language_ssim',
    abstract: 'abstract_ssi',
    department: 'department_ssim',
    genre: 'genre_ssim',
    created_at: 'record_creation_dtsi',
    id: 'cul_doi_ssi',
    legacy_id: 'id',
    modified_at: 'record_change_dtsi',
    degree_name: 'degree_name_ssim',
    degree_level: 'degree_level_name_ssim',
    degree_grantor: 'degree_grantor_ssim',
    degree_discipline: 'degree_discipline_ssim',
    columbia_series: 'series_ssim', # Only columbia series.
    thesis_advisor: 'thesis_advisor_ssim',
    embargo_end: 'free_to_read_start_date_ssi',
    notes: 'notes_ssim',
    author_id: 'author_uni_ssim'
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
    @semantic_value_hash[:persistent_url] = full_doi
    @semantic_value_hash[:date] = @semantic_value_hash[:date].map(&:to_s)

    @semantic_value_hash
  end

  def doi
    fetch(:cul_doi_ssi, nil)
  end

  def full_doi
    AcademicCommons.identifier_url(doi)
  end

  def assets(include_inactive: false)
    return [] unless free_to_read?(self)
    obj_display = fetch('fedora3_pid_ssi', nil)

    member_search = {
      qt: 'search',
      fl: '*',
      fq: ["cul_member_of_ssim:\"info:fedora/#{obj_display}\""],
      rows: 10_000,
      facet: false
    }
    member_search[:fq] << 'object_state_ssi:A' unless include_inactive
    response = Blacklight.default_index.connection.get 'select', params: member_search
    docs = response['response']['docs']
    @assets ||= docs.map { |member| SolrDocument.new(member) }
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
      :download, fetch('id', nil),
      fetch('downloadable_content_dsid_ssi'),
      fetch('downloadable_content_label_ss')
    )
  end

  def asset?
    ['GenericResource', 'Resource'].include?(fetch(:active_fedora_model_ssi, nil))
  end

  def pages
    fields = [fetch('start_page_ssi', nil), fetch('end_page_ssi', nil)].compact
    fields.blank? ? nil : fields.join(' - ')
  end

  def degree
    fields = [fetch('degree_name_ssim', nil), fetch('degree_grantor_ssim', nil)].compact
    fields.blank? ? nil : fields.join(', ')
  end
end
