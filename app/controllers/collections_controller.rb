class CollectionsController < ApplicationController
  CONFIG = {
    series: {
      title: 'Paper and Report Series',
      summary: 'View working paper and report series created by Columbia departments and centers.',
      facet: 'series_ssim'
    },
    featured: {
      title: 'Featured Collections',
      summary: 'Browse collections of research produced by Columbia programs, institutes, and centers.',
      facet: 'department_ssim',
      values: [
        'Center on Japanese Economy and Business',
        'Columbia Center on Sustainable Investment',
        'Community College Research Center',
        'National Center for Disaster Preparedness',
        'Tow Center for Digital Journalism'
      ]
    },
    doctoraltheses: {
      title: 'Doctoral Theses',
      summary: 'View full-text Columbia doctoral theses from 2011 forward. Some theses dated prior to 2011 are also available.',
      filter: { genre_ssim: 'Theses', degree_level_name_ssim: 'Doctoral' },
      facet: 'department_ssim'
    },
    journals: {
      title: 'Columbia Journals',
      summary: 'Explore articles from a selection of journals published at Columbia.',
      facet: 'cu_journal_ssim'
    }
  }.freeze

  # GET /collections
  def index
    @categories = collections_config.values
  end

  # GET /collections/:category_id
  def show
    raise StandardError unless valid_category?(params[:category_id])

    # check that the category_id is valid
    # if not valid render page not found (404)
    # if category id is valid look up any additional solr parameters
    @category = collections_config[params[:category_id].to_sym]
    response = AcademicCommons.search do |parameters|
      parameters.rows(0).facet_limit(-1).facet_by(@category.facet)
      if (filters = @category.filter)
        filters.each { |f, v| parameters.filter(f, v) }
      end
    end

    facet_counts = response.facet_fields[@category.facet].each_slice(2).to_a.to_h
    facet_counts.keep_if { |k, _| @category.values.include?(k) } if @category.values

    @collections = facet_counts.map do |value, count|
      filters = { @category.facet => value }.merge(@category.filters || {})
      OpenStruct.new(label: value, count: count, search_url: search_url(filters))
    end
  end

  private

  def collections_config
    @collections_config ||= generate_config
  end

  def generate_config
    c = {}

    CONFIG.each do |category, config|
      struct = OpenStruct.new(config)
      struct.url = "/collections/#{category}"
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
