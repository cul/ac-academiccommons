class SolrDocument
  include Blacklight::Solr::Document
  include AcademicCommons::Embargoes

  SolrDocument.use_extension( BlacklightOaiProvider::SolrDocumentExtension )


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
  field_semantics.merge!(
                         :title => "title_display",
                         :author => "author_facet",
                         :format => "format",
			 :creator => "author_facet",
			 :date => "date_issued",
			 :type => "type_of_resource_mods",
			 :publisher => "publisher",
			 :subject => "subject_facet",
			 :identifier => "handle",
			 :description => "abstract",
			 :language => "language"
                         )


  def record_creation_date
    Time.parse get('record_creation_date')
  end

  def embargoed?
    !free_to_read?(self)
  end

  def restricted?
    has?(:restriction_on_access_ss)
  end

  def access_restriction
    fetch(:restriction_on_access_ss)
  end
end
