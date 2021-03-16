class CollectionsController < ApplicationController
  CONFIG = {
    featured: {
      title: 'Featured Partners',
      summary: 'Works shared by eight Columbia research centers. Want to showcase the work of your department or center here? Contact us at <a href="mailto:ac@columbia.edu">ac@columbia.edu</a>',
      facet: 'department_ssim'
    },
    doctoraltheses: {
      title: 'Doctoral Theses',
      summary: 'Full-text Columbia dissertations from 2011 forward. Some dissertations dated prior to 2011 are also available.',
      filter: {
        genre_ssim: 'Theses',
        degree_level_name_ssim: 'Doctoral',
        degree_grantor_ssim: '("Columbia University" OR "Teachers College, Columbia University" OR "Union Theological Seminary" OR "Mailman School of Public Health, Columbia University")'
      },
      facet: 'department_ssim'
    },
    producedatcolumbia: {
      title: 'Produced at Columbia',
      summary: 'Series of working papers, event videos, and more from departments and centers on campus.',
      facet: 'series_ssim'
    },
    journals: {
      title: 'Columbia Journals',
      summary: 'The ongoing archives of journals published in collaboration with Columbia University Libraries.',
      facet: 'partner_journal_ssi'
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
    raise(ActionController::RoutingError, 'not found') unless valid_category?(params[:category_id])

    # If category_id is valid look up any additional solr parameters
    @category = send params[:category_id].to_sym
    response = AcademicCommons.search do |parameters|
      parameters.rows(0).facet_limit(-1).facet_by(@category.facet)
      if (filters = @category.filter)
        filters.each { |f, v| parameters.filter(f, v) }
      end
    end

    facet_counts = response.facet_fields[@category.facet].each_slice(2).to_a.to_h
    facet_counts.keep_if { |k, _| @category.values.keys.include?(k) } if @category.values

    @collections = facet_counts.map do |value, count|
      filters = { @category.facet => value }.merge(@category.filter || {})
      c = OpenStruct.new(label: value, count: count, search_url: search_url(filters))
      c.description = @category.values[value] if @category.values
      c
    end
  end

  def featured
    config = collections_config[:featured]
    unless config.values
      feature_category = FeatureCategory.find_by(field_name: config.facet)
      if feature_category
        values = feature_category.featured_searches.all.order("filter_value ASC").map { |feature|
          [feature.filter_value, feature.description]
        }.to_h
        config.values = values
      end
    end
    config
  end

  def doctoraltheses
    collections_config[:doctoraltheses]
  end

  def producedatcolumbia
    collections_config[:producedatcolumbia]
  end

  def journals
    collections_config[:journals]
  end

  private

  def collections_config
    @collections_config ||= generate_config
  end

  def generate_config
    c = {}

    CONFIG.each do |category, config|
      struct = OpenStruct.new(config)
      struct.url = collection_path(category_id: category)
      struct.top_partial = "#{category}_top"
      struct.bottom_partial = "#{category}_bottom"
      c[category] = struct
    end

    c
  end

  def search_url(filters)
    filters.transform_values! { |v| Array.wrap(v) }
    facet_params = search_state.reset.params_for_search(f: filters)
    search_action_path(facet_params)
  end

  def valid_category?(category)
    collections_config[category.to_sym]
  end
end
