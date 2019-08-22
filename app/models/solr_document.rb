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
      @semantic_value_hash[:persistent_url] = full_doi
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
      obj_display = fetch('fedora3_pid_ssi', nil)

      member_search = {
        qt: 'search',
        fl: '*',
        fq: ["cul_member_of_ssim:\"info:fedora/#{obj_display}\"", 'object_state_ssi:A'],
        rows: 10_000,
        facet: false
      }
      response = Blacklight.default_index.connection.get 'select', params: member_search
      docs = response['response']['docs']
      @assets = docs.map { |member| SolrDocument.new(member) }
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

  def title
    to_semantic_values[:title].first
  end

  def genre
    to_semantic_values[:genre].first
  end

  def created_at
    to_semantic_values[:created_at].first
  end

  def video?
    asset? && (dc_type.include?('MovingImage') || dc_type.include?('Video'))
  end

  def audio?
    asset? && (dc_type.include?('Sound') || dc_type.include?('Audio'))
  end

  def image_url(size = 256)
    return nil unless asset?
    "#{Rails.application.secrets.iiif[:urls].sample}/#{fetch(:fedora3_pid_ssi)}/full/!#{size},#{size}/0/native.jpg"
  end

  def wowza_media_url(request)
    raise ArgumentError, 'Request object invalid' unless request.is_a?(ActionDispatch::Request)
    return unless audio? || video?
    # Check that it is free to read

    wowza_config = Rails.application.secrets[:wowza]
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

  private

  def dc_type
    fetch('dc_type_ssm', [])
  end
end
