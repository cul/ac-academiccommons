class CollectionsController < ApplicationController
  CONFIG = {
    featured: {
      title: 'Featured Partners',
      summary: 'Works shared by eight Columbia research centers. Want to showcase the work of your department or center here? Contact us at <a href="mailto:ac@columbia.edu">ac@columbia.edu</a>',
      facet: 'department_ssim',
      filter: {}
    },
    doctoraltheses: {
      title: 'Doctoral Theses',
      summary: 'Full-text Columbia dissertations from 2011 forward. Some dissertations dated prior to 2011 are also available.',
      facet: 'department_ssim',
      filter: {
        genre_ssim: 'Theses',
        degree_level_name_ssim: 'Doctoral',
        degree_grantor_ssim: '("Columbia University" OR "Teachers College, Columbia University" OR "Union Theological Seminary" OR "Mailman School of Public Health, Columbia University")'
      },
      labels: {}
    },
    producedatcolumbia: {
      title: 'Produced at Columbia',
      summary: 'Series of working papers, event videos, and more from departments and centers on campus.',
      facet: 'series_ssim',
      filter: {}, labels: {}
    },
    journals: {
      title: 'Columbia Journals',
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

  # GET /explore/:category_id
  # NB custom resource path for collections
  def show
    # Render 404 if category_id not valid
    raise(ActionController::RoutingError, 'not found') unless collections_config[params[:category_id].to_sym]

    # If category_id is valid look up any additional solr parameters
    @category = send params[:category_id].to_sym
    facet_name = @category.queries ? "featured_search" : @category.facet
    response = AcademicCommons.search do |parameters|
      parameters.rows(0).facet_limit(-1)
      if @category.queries # {!ex=pt key=valueKey}field:query
        @category.queries.each { |key, query| parameters.add_facet_query "{!ex=featured_search key=#{key}}#{query}" }
      else
        parameters.facet_by(facet_name)
        @category.filter.each { |f, v| parameters.filter(f, v) }
      end
    end

    facet_counts = @category.queries ? response.facet_queries : response.facet_fields[facet_name].each_slice(2).to_a.to_h
    facet_counts.keep_if { |k, _| @category.values.keys.include?(k) } if @category.values

    @collections = facet_counts.map do |value, count|
      filters = { facet_name => value }.merge(@category.filter)
      c = OpenStruct.new(label: value, count: count, search_url: search_url(filters))
      c.label = @category.labels.fetch(value, value)
      c.description = @category.values&.fetch(value, nil)
      c
    end
  end

  def featured
    config = collections_config[:featured]
    add_category_data(config) unless config.values
    config
  end

  def doctoraltheses
    collections_config[:doctoraltheses]
  end

  def producedatcolumbia
    collections_config[:producedatcolumbia]
  end

  def journals
    config = collections_config[:journals]
    add_category_data(config) unless config.values
    config
  end

  private

  def add_category_data(config)
    config.labels = {}
    config.queries = {}
    config.values = {}
    feature_category = FeatureCategory.find_by(field_name: config.facet)
    return unless feature_category
    feature_category.featured_searches.all.order("label ASC").map do |feature|
      config.values[feature.slug] = feature.description
      config.labels[feature.slug] = feature.label
      config.queries[feature.slug] = AcademicCommons::FeaturedSearches.to_fq(feature)
    end
  end

  def collections_config
    @collections_config ||= CONFIG.map { |category, config|
      struct = OpenStruct.new(config)
      struct.url = collection_path(category_id: category)
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
