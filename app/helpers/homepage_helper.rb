module HomepageHelper
  # Generates url for type faceted search
  def type_search(type)
    facet_params = search_state.reset.add_facet_params('genre_ssim', type)
    search_action_path(facet_params)
  end

  # Generate url for dissertation search
  def dissertation_search
    facet_params = search_state.reset.params_for_search(
      f: { 'genre_ssim' => ['Theses'], 'degree_level_name_ssim' => ['Doctoral'] }
    )
    search_action_path(facet_params)
  end

  def counts
    @counts ||= calculate_type_counts
  end

  # Calculates statistics for display on the homepage.
  def calculate_type_counts
    solr_response = AcademicCommons.search do |p|
      p.aggregators_only.rows(0).facet_by('genre_ssim', 'degree_level_name_ssim').facet_limit(-1)
    end

    genre_counts   = solr_response.facet_fields['genre_ssim'].each_slice(2).to_a.to_h
    doctoral_count = solr_response.facet_fields['degree_level_name_ssim'].each_slice(2).to_a.to_h

    {
      all:                  solr_response.total,
      articles:             genre_counts['Articles'],
      reports:              genre_counts['Reports'],
      doctoral_theses:      doctoral_count['Doctoral'],
      conference_materials: genre_counts['Conference objects'],
      datasets:             genre_counts['Data (information)']
    }.transform_values { |v| number_with_delimiter(v.to_i) }
  end
end
