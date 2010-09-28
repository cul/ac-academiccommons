class StatisticsController < ApplicationController
  layout "no_sidebar"


  def author_monthly


    if params[:commit] == "View"
      startdate = Date.parse(params[:month] + " " + params[:year])
      enddate = startdate + 1.month
      events = ["View", "Download"]
      @results = Blacklight.solr.find(:per_page => 10000, :sort => "title_display asc" , :fq => "author_id_uni:#{params[:author_id]}", :fl => "title_display,id", :page => 1)["response"]["docs"]
      ids = @results.collect { |r| r["id"] }
      @stats = {}
      @totals = {}
      events.each do |event|

        @stats[event] = Statistic.count(:group => "identifier", :conditions => ["event = ? and identifier IN (?) AND at_time BETWEEN ? and ?", event, ids,startdate, enddate])
        @totals[event] = @stats[event].values.inject { |sum,x| sum ? sum+x : x}
      end
     
      @results.reject! { |r| params[:exclude_zeroes] && !@stats["View"][r["id"]] && !@stats["Download"][r["id"]] }
      @results.sort! do |x,y|
        result = (@stats["Download"][y["id"]] || 0) <=> (@stats["Download"][x["id"]] || 0) 
        result = x["title_display"] <=> y["title_display"] if result == 0
        result
      end
    end
     

  end

  def item_history
    params[:event] ||= ["View"]
    
    six_months_ago = Date.today - 6.months
    next_month = Date.today + 1.months
    params[:start_date] ||= Date.civil(six_months_ago.year, six_months_ago.month).to_formatted_s(:datepicker)
    params[:end_date] ||= (Date.civil(next_month.year, next_month.month) - 1.day).to_formatted_s(:datepicker)

    unless params[:id]
      flash[:error] = "No ID specified."
      redirect_to root_path
    end

    if params[:commit] == "View Statistics"
      @results = Statistic.count_intervals(:identifier => params[:id], :event => params[:event], :start_date => DateTime.parse(params[:start_date]), :end_date => DateTime.parse(params[:end_date]), :group => params[:group].downcase.to_sym)
      date_format = ("chart_" + params[:group]).downcase.to_sym

      chart_params = {:size => "700x400", :title => "Statistics for #{params[:id]}|#{params[:start_date]} to #{params[:end_date]}", :axis_with_labels => "x,y,x", :data => [], :legend => [], :bg => "F6F6F6", :line_colors => [], :custom => "chxs=0,676767,11.5,0,lt,676767"}

      events = @results.keys
      data_hash = Hash.new { |h,k| h[k] = [] }

      max_y = (([@results.values.collect { |s| s.values }.flatten.max, 100].max + 100)/ 100) * 100    
      y_labels = (0..4).collect { |part| part * max_y / 4 }

      dates = @results.values.collect { |s| s.keys}.flatten.uniq.sort
      formatted_dates = dates.collect { |d| d.to_formatted_s(date_format) }
      dates_top = []
      dates_bottom = []

      legend_hash = { "View" => "Views", "Download" => "Downloads" }
      colors_hash = { "View" => "0022FF", "Download" => "FF00CC" }

      if formatted_dates.length > 15
        formatted_dates.each_with_index do |date, i|
          dates_top << (i % 2 == 0 ? date : "")
          dates_bottom << (i % 2 == 0 ? "" : date)
        end
        chart_params[:axis_labels] = [dates_top, y_labels, dates_bottom]
      else
        chart_params[:axis_labels] = [formatted_dates, y_labels, []]
      end

      dates.each do |date|
        events.each do |event|
          data_hash[event] << @results[event][date] || 0
        end
      end

      events.each do |event|
        chart_params[:data] << data_hash[event]
        chart_params[:legend] << legend_hash[event]
        chart_params[:line_colors] << colors_hash[event]
      end

      chart_params[:line_colors] = chart_params[:line_colors].join(",")
      if params[:group] == "Year"
        chart_params[:custom] += "&chma=150,25,25,25"
        @chart = Gchart.bar(chart_params.merge(:stacked => false))
      else
        chart_params[:custom] += "&chma=50,25,25,25"
        @chart = Gchart.line(chart_params)
      end
    end


  end
end
