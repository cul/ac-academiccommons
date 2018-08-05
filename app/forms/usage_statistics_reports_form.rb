class UsageStatisticsReportsForm < FormObject
  MONTHS = Date::ABBR_MONTHNAMES.dup[1..12].freeze

  attr_accessor :filters, :time_period, :order, :display, :usage_stats,
                :start_date, :end_date

  #  :format => :email, :csv, :html

  # validates :time_period, :order, :display, presence: true
  # if time_period is range, then start and end date need to be populated

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
  }.freeze

  ORDER = {
    'Title (A-Z)' => 'title',
    'Most Views' => 'views',
    'Most Downloads' => 'downloads'
  }.freeze

  def generate_statistics
    return false unless valid?

    solr_params = AcademicCommons::SearchParameters.new
    (filters || {}).each do |f|
      next if f[:field].blank? || f[:value].blank?
      solr_params.filter(f[:field], f[:value])
    end

    options = {}
    options[:per_month] = true if display == 'month_by_month'
    options[:order] = order || nil

    if time_period == 'lifetime'
      s_date = Date.new(Statistic::YEAR_BEG).in_time_zone
      e_date = Date.current.prev_month.end_of_month
    elsif time_period == 'month_by_month'
      s_date = Date.parse("#{start_date[:month]} #{start_date[:year]}").in_time_zone
      e_date = Date.parse("#{end_date[:month]} #{end_date[:year]}").in_time_zone
    end

    @usage_stats = AcademicCommons::Metrics::UsageStatistics.new(
      solr_params.to_h, s_date, e_date, options
    )
  end
end
