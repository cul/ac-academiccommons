class UsageStatisticsReportsForm < FormObject
  attr_accessor :filters, :time_period, :order, :options, :display, :usage_stats

  #  :format => :email, :csv, :html

  # validates :time_period, :order, :display, presence: true

  FILTERS = {
    'Author Name'    => SolrDocument.field_semantics[:author],
    'Year'           => SolrDocument.field_semantics[:date],
    'Genre'          => SolrDocument.field_semantics[:genre],
    'Subject'        => SolrDocument.field_semantics[:subject],
    # 'Resource Type', => SolrDocument.field_semantics[:],
    'Organization'   => SolrDocument.field_semantics[:organization],
    'Department'     => SolrDocument.field_semantics[:department],
    'Series'         => SolrDocument.field_semantics[:columbia_series],
    'Non CU Series'  => SolrDocument.field_semantics[:non_columbia_series],
    'UNI'            => SolrDocument.field_semantics[:author_id]
  }

  ORDER = {
    'Title (A-Z)' => 'title',
    'Most Views' => 'views',
    'Most Downloads' => 'downloads'
  }

  def generate_statistics
    Rails.logger.debug "in generate_statistics"

    return false unless valid?
    # options = {}
    # options[:include_zeroes] = true if options.include?('include_zeroes')
    # options[:include_views] =
    solr_params = AcademicCommons::SearchParameters.new
    # (filters || {}).each { |f, v| solr_params.filter(f, v) }

    if time_period == 'lifetime'
      @usage_stats = AcademicCommons::Metrics::UsageStatistics.new(solr_params.to_h)
      Rails.logger.debug usage_stats.inspect
    else
      usage_stats = AcademicCommons::Metrics::UsageStatistics.new(
        solr_params, startdate, enddate,
        order_by: order, include_zeroes: options[:include_zeroes],
      )
    end
  end
end
