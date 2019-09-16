class UsageStatisticsPresenter
  attr_accessor :usage_stats, :display, :view

  def initialize(usage_stats, display, view)
    @usage_stats = usage_stats
    @display = display # Display for statistics, month-to-month, period or lifetime
    @view = view
  end

  def render_details_table
    view.content_tag :ul, class: 'two-col' do
      view.safe_join(
        usage_stats.report_details.map { |a|
          view.content_tag :li, view.content_tag(:b, a[0]) + ' ' + a[1].to_s
        }
      )
    end
  end

  def render_html_table(table_class: nil, heading: :h4)
    case display
    when :lifetime
      array = usage_stats.lifetime_table
      html_table(array, table_class: table_class)
    when :period
      array = usage_stats.time_period_table
      html_table(array, table_class: table_class)
    when :month_by_month
      view.content_tag(heading, 'Views')
          .concat(html_table(usage_stats.month_by_month_table(Statistic::VIEW), table_class: table_class))
          .concat(view.content_tag(heading, 'Downloads'))
          .concat(html_table(usage_stats.month_by_month_table(Statistic::DOWNLOAD), table_class: table_class))
    end
  end

  private

    def html_table(array, table_class: nil)
      view.content_tag :table, class: table_class do
        view.content_tag(:thead, view.content_tag(:tr, row(:th, array[0])))
            .concat(view.content_tag(:tbody, body_rows(array[1..-2])))
            .concat(view.content_tag(:tfoot, view.content_tag(:tr, row(:th, array[-1]))))
      end
    end

    def body_rows(array_of_arrays)
      view.safe_join(array_of_arrays.map { |row| view.content_tag :tr, row(:td, row) })
    end

    def row(tag, array)
      view.safe_join(array.map { |cell| view.content_tag(tag, cell) })
    end
end
