class CollectionsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :ensure_canonical_url, only: :show
  # This CONFIG object holds all of the data for each available category page.
  # Note:
  #   - the 'legacy_url' field is used for mapping the old URLs to the new canonical kebab-case format
  CONFIG = {
    featured_partners: {
      title: 'Featured Partners',
      slug: 'featured-partners',
      summary: 'Works shared by our partner centers and departments. These groups actively collaborate with repository staff to provide long-term access to their research.',
      facet: 'department_ssim',
      legacy_url: 'featured',
      filter: {}
    },
    doctoral_theses: {
      title: 'Doctoral Theses',
      slug: 'doctoral-theses',
      summary: 'Full-text Columbia dissertations from 2011 forward. Some dissertations dated prior to 2011 are also available.',
      facet: 'department_ssim',
      filter: {
        genre_ssim: 'Theses',
        degree_level_name_ssim: 'Doctoral',
        degree_grantor_ssim: '("Columbia University" OR "Teachers College, Columbia University" OR "Union Theological Seminary" OR "Mailman School of Public Health, Columbia University")'
      },
      legacy_url: 'doctoraltheses',
      values: {}
    },
    produced_at_columbia: {
      title: 'Produced at Columbia',
      slug: 'produced-at-columbia',
      summary: 'Series of working papers, event videos, and more from departments and centers on campus.',
      facet: 'series_ssim',
      filter: {},
      values: {},
      legacy_url: 'producedatcolumbia',
      # We do not display produced at columbia on the explore page, but link to its show view in the featured series show view (bottom partial).
      hide_in_index_view: true
    },
    featured_series: {
      title: 'Featured Series',
      slug: 'featured-series',
      summary: 'Collections of materials produced at Columbia, including working papers series, white papers, event videos, podcast archives, and curriculum guides.',
      facet: 'series_ssim',
      hide_thumbnails?: true,
      # This has no legacy URL
      filter: {}
    },
    journals: {
      title: 'Columbia Journals',
      slug: 'journals',
      summary: 'The ongoing archives of journals published in collaboration with Columbia University Libraries.',
      facet: 'partner_journal_ssi',
      filter: {}
    }
  }.freeze

  # GET /explore
  # NB custom resource path for collections
  def index
    @categories = collections_config.values
  end

  # GET /explore/:category_slug
  # NB custom resource path for collections
  def show
    # Find the ID associated with the slug
    category_id = collections_config.find { |_category_id, config| config.slug == params[:category_slug] }&.first
    # Render 404 if category_id not valid
    raise(ActionController::RoutingError, 'not found') if category_id.nil?

    # If category_id is valid look up any additional solr parameters
    @category = send category_id
    facet_name = @category.use_queries ? "featured_search" : @category.facet
    response = AcademicCommons.search do |parameters|
      parameters.rows(0).facet_limit(-1)
      if @category.use_queries # {!ex=pt key=valueKey}field:query
        @category.values.each { |key, value| parameters.add_facet_query "{!ex=featured_search key=#{key}}#{value.query}" }
      else
        parameters.facet_by(facet_name)
        @category.filter.each { |f, v| parameters.filter(f, v) }
      end
    end

    facet_counts = @category.use_queries ? response.facet_queries : response.facet_fields[facet_name].each_slice(2).to_a.to_h
    facet_counts.keep_if { |k, _| @category.values.keys.include?(k) } if @category.values.present?

    @collections = facet_counts.map do |value, count|
      filters = { facet_name => value }.merge(@category.filter)
      c = @category.values.fetch(value, OpenStruct.new(label: value))
      c.count = count
      c.search_url = search_url(filters)
      c
    end
  rescue Blacklight::Exceptions::InvalidRequest
    Rails.logger.error 'A problem occurred querying the solr index -- make sure all featured searches are valid! Manage these values at /admin/featured_searches.'
    @collections = [] if @collections.nil?
  end

  def featured_series
    config = collections_config[:featured_series]
    add_category_data(config) unless config.values
    config
  end

  def featured_partners
    config = collections_config[:featured_partners]
    add_category_data(config) unless config.values
    config
  end

  def doctoral_theses
    collections_config[:doctoral_theses]
  end

  def produced_at_columbia
    collections_config[:produced_at_columbia]
  end

  def journals
    config = collections_config[:journals]
    add_category_data(config) unless config.values
    config
  end

  private

  # Maps old URLs (which use older versions of the collections_config category_id's) to their corresponding
  # newer versions (which separate words with underscores)
  def legacy_urls_hash
    @legacy_urls_hash ||= collections_config.each_with_object({}) do |(_category, config), hash|
      hash[config.legacy_url] = config.url if config.legacy_url
    end
  end

  # Translate any old slugs to their new,
  def ensure_canonical_url
    return unless legacy_urls_hash.keys.include? params[:category_slug]
    redirect_to legacy_urls_hash[params[:category_slug]], status: :moved_permanently
  end

  def add_category_data(config)
    config.values = {}
    config.use_queries = true
    feature_category = FeatureCategory.find_by(field_name: config.facet)
    return unless feature_category
    feature_category.featured_searches.all.order("label ASC").each do |feature|
      struct_data = { value: feature.slug, query: AcademicCommons::FeaturedSearches.to_fq(feature) }
      [:description, :image_url, :label, :url].each { |key| struct_data[key] = feature.send(key) }
      config.values[feature.slug] = OpenStruct.new(struct_data)
    end
  end

  def collections_config
    @collections_config ||= CONFIG.map { |category, config|
      struct = OpenStruct.new(config)
      struct.url = collection_path(category_slug: struct.slug)
      struct.top_partial = "#{category}_top"
      struct.bottom_partial = "#{category}_bottom"
      [category, struct]
    }.to_h
  end

  def search_url(filters)
    filters.transform_values! { |v| Array.wrap(v) }
    facet_params = search_state.reset.params_for_search(f: filters)
    search_action_path(facet_params)
  end
end
