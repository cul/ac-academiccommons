require 'academic_commons'
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument
  include AcademicCommons::Embargoes
  include Document::SchemaOrg

  # self.unique_key = 'id'
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
    id: 'id',
    legacy_id: 'fedora3_pid_ssi',
    modified_at: 'record_change_dtsi',
    degree_name: 'degree_name_ssim',
    degree_level: 'degree_level_name_ssim',
    degree_grantor: 'degree_grantor_ssim',
    degree_discipline: 'degree_discipline_ssim',
    columbia_series: 'series_ssim', # Only columbia series.
    non_columbia_series: 'non_cu_series_ssim',
    thesis_advisor: 'thesis_advisor_ssim',
    embargo_end: 'free_to_read_start_date_ssi',
    notes: 'notes_ssim',
    author_id: 'author_uni_ssim',
    organization: 'organization_ssim',
    resource_type: 'type_of_resource_ssim'
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

  # Generates semantic_value_hash, overridden to add custom fields.
  def to_semantic_values
    unless @semantic_value_hash
      super
      # Custom values
      @semantic_value_hash[:identifier] = full_doi
      @semantic_value_hash[:date] = @semantic_value_hash[:date].map(&:to_s)
    end

    @semantic_value_hash
  end

  def doi
    fetch(:cul_doi_ssi, nil)
  end

  def full_doi
    AcademicCommons.identifier_url(doi)
  end

  # Returns all active child assets.
  def assets
    return @assets if @assets

    if free_to_read?(self)
      # check if solr response already included assets
      if (asset_response = fetch('assets', nil))
        @assets = Blacklight::Solr::Response.new({ response: asset_response }, {}).docs
      else
        item_pid = fetch('fedora3_pid_ssi', nil)

        @assets = AcademicCommons.search { |p| p.assets_for(item_pid) }.docs
      end
    else
      @assets = []
    end
  rescue StandardError => e
    Rails.logger.error e.message
    return []
  end

  def thumbnail
    image_url(256)
  end

  def filename
    return nil unless asset?
    fetch('downloadable_content_label_ss', nil)
  end

  def download_path
    return nil unless asset?
    Rails.application.routes.url_helpers.content_download_path(id)
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

  field_semantics.except(:id).each do |field, solr_key|
    define_method(field) do
      solr_key.ends_with?('m') ? fetch(solr_key, []) : fetch(solr_key, nil)
    end
  end

  def video?
    asset? && (dc_type.include?('MovingImage') || dc_type.include?('Video'))
  end

  def audio?
    asset? && (dc_type.include?('Sound') || dc_type.include?('Audio'))
  end

  def playable?
    video? || audio?
  end

  def captions?
    fetch('datastreams_ssim', []).include?('captions')
  end

  def image_url(size = 256)
    return nil unless asset?
    "#{Rails.application.secrets.iiif[:urls].sample}/#{fetch(:fedora3_pid_ssi)}/full/!#{size},#{size}/0/native.jpg"
  end

  def wowza_media_url(request)
    raise ArgumentError, 'Request object invalid' unless request.is_a?(ActionDispatch::Request)
    return unless playable?
    # Check that it is free to read

    wowza_config = Rails.application.secrets[:wowza]
    raise 'Missing wowza config' unless wowza_config

    access_copy_location = fetch('access_copy_location_ssi', nil)&.gsub(/^file:/, '')

    return unless access_copy_location

    Wowza::SecureToken::Params.new(
      stream: wowza_config[:application] + '/_definst_/mp4:' + access_copy_location.gsub(%r{^\/}, ''),
      secret: wowza_config[:shared_secret],
      client_ip: request.remote_ip,
      starttime: Time.now.to_i,
      endtime: Time.now.to_i + wowza_config[:token_lifetime].to_i,
      prefix: wowza_config[:token_prefix]
    ).to_url_with_token_hash(wowza_config[:host], wowza_config[:ssl_port], 'hls-ssl')
  end

  def related_items
    related_items = JSON.parse(fetch('related_items_ss', '[]')).map do |related_item|
      {
        relation_type: related_item['relation_type'],
        title: related_item['title'].present? ? related_item['title'] : related_item['identifier']['value'],
        link: related_item_link(related_item['identifier']['type'], related_item['identifier']['value'])
      }
    end
    related_items.sort_by { |related_item| AcademicCommons::DescMetadata::ORDERED_RELATED_ITEM_TYPES.find_index(related_item[:relation_type]) }
  end

  def related_item_link(type, value)
    case type
    when 'doi'
      'https://doi.org/' + value
    when 'issn'
      'https://www.worldcat.org/issn/' + value.remove('-')
    when 'isbn'
      'https://www.worldcat.org/isbn/' + value.remove('-')
    else
      value
    end
  end

  private

  def dc_type
    fetch('dc_type_ssm', [])
  end
end
