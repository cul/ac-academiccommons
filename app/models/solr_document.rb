require 'academic_commons'
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument
  include AcademicCommons::Embargoes

  self.timestamp_key = 'record_creation_date'

  # The following shows how to setup this blacklight document to display marc documents
  # extension_parameters[:marc_source_field] = :marc_display
  # extension_parameters[:marc_format_type] = :marcxml
  # use_extension( Blacklight::Solr::Document::Marc) do |document|
  #   document.key?( :marc_display  )
  # end

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)

  # Normalized field names
  field_semantics.merge!(
    id: 'handle',
    legacy_id: 'id',
    title: "title_display",
    author: "author_facet",
    creator: "author_facet",
    date: "pub_date_facet",
    type: "genre_facet",
    publisher: "publisher",
    subject: "subject_facet",
    description: "abstract",
    language: "language",
    abstract: "abstract",
    department: "department_facet",
    genre: "genre_facet",
    created_at: "record_creation_date",
    modified_at: 'record_change_date',
    degree_name: 'degree_name_ssim',
    degree_level: 'degree_level_name_ssim',
    degree_grantor: 'degree_grantor_ssim'
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

    @semantic_value_hash
  end

  def full_doi
    AcademicCommons.identifier_url(fetch(:handle, nil))
  end
end
