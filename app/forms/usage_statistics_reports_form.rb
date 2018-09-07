class UsageStatisticsReportsForm < FormObject
  MONTHS = Date::ABBR_MONTHNAMES.dup[1..12].freeze
  DISPLAY_OPTIONS = ['summary', 'month_by_month'].freeze
  TIME_PERIOD_OPTIONS = ['date_range', 'lifetime'].freeze

  FILTERS = {
    'Author Name'    => SolrDocument.field_semantics[:author],
    'UNI'            => SolrDocument.field_semantics[:author_id],
    'Year'           => SolrDocument.field_semantics[:date],
    'Genre'          => SolrDocument.field_semantics[:genre],
    'Subject'        => SolrDocument.field_semantics[:subject],
    'Resource Type'  => SolrDocument.field_semantics[:resource_type],
    'Organization'   => SolrDocument.field_semantics[:organization],
    'Department'     => SolrDocument.field_semantics[:department],
    'Series'         => SolrDocument.field_semantics[:columbia_series],
    'Non CU Series'  => SolrDocument.field_semantics[:non_columbia_series],
    'CUL DOI'        => SolrDocument.field_semantics[:id]
  }.freeze

  ORDER = {
    'Title (A-Z)' => 'Title',
    'Most Views' => Statistic::VIEW,
    'Most Downloads' => Statistic::DOWNLOAD
  }.freeze

  attr_accessor :filters, :time_period, :order, :display, :usage_stats,
                :start_date, :end_date, :requested_by

  validates :time_period, :display, presence: true
  validates :start_date, :end_date, presence: true, if: proc { |a| a.time_period == 'date_range' }
  validates :display,     inclusion: { in: DISPLAY_OPTIONS }
  validates :time_period, inclusion: { in: TIME_PERIOD_OPTIONS }
  validates :order,       inclusion: { in: ORDER.values }, unless: proc { |a| a.order.blank? }
  validate  :filters_must_have_a_value

  def generate_statistics
    return false unless valid?

    solr_params = AcademicCommons::SearchParameters.new
    (filters || {}).each do |f|
      next if f[:field].blank? || f[:value].blank?
      solr_params.filter(f[:field], f[:value])
    end

    if time_period == 'lifetime' && display == 'month_by_month'
      s_date = Time.zone.parse("Jan #{Statistic::YEAR_BEG}")
      e_date = Time.current.prev_month.end_of_month
    elsif time_period == 'date_range'
      s_date = Time.zone.parse("#{start_date[:month]} #{start_date[:year]}")
      e_date = Time.zone.parse("#{end_date[:month]} #{end_date[:year]}").end_of_month
    else
      s_date = nil
      e_date = nil
    end

    @usage_stats = AcademicCommons::Metrics::UsageStatistics.new(
      solr_params: solr_params.to_h, start_date: s_date, end_date: e_date, requested_by: requested_by
    )

    @stat_key = if display == 'month_by_month'
                  :month_by_month
                elsif time_period == 'date_range'
                  :period
                elsif time_period == 'lifetime'
                  :lifetime
                end

    usage_stats.send("calculate_#{@stat_key}")
    usage_stats.order_by(@stat_key, order) if order != 'Title' && @stat_key != :month_by_month

    true
  end

  def to_csv
    usage_stats.send("#{@stat_key}_csv")
  end

  private

  def filters_must_have_a_value
    errors.add(:filters, 'must have a field and value') if (filters || {}).any? { |f| f[:field].present? && f[:value].blank? }
  end
end
