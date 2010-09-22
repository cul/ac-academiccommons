class StatisticsController < ApplicationController
  layout "no_sidebar"

  def item_history
    case params[:grouping]
    when "year"
      group_by = "YEAR(at_time)"
    when "month"
      group_by = "YEAR(at_time), MONTH(at_time)"
    when "week"
      group_by = "YEAR(at_time), MONTH(at_time), WEEK(at_time)"
    else
      group_by = "Year(at_time), MONTH(at_time)"
    end


    Statistic.count(:conditions => {:identifier => params[:id], :event => "show"})
  end
end
