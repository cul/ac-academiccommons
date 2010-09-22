class Statistic < ActiveRecord::Base

  # warning: MYSQL only
  def self.count_intervals(options = {})
    group = options[:group] || :month
    raise(ArgumentError, "invalid group parameter") unless group.in?(:month, :year, :week)



    results = {}
    conditions = {}

    conditions[:start_date] = options[:start_date] || Time.now - 6.months
    conditions[:end_date] = options[:end_date] || Time.now
    conditions[:event] = options[:event] || "show"
    conditions[:identifier] = options[:identifier]

    condition_text = "statistics.at_time >= :start_date and  statistics.at_time <= :end_date AND statistics.event = :event"
    condition_text += " AND statistics.identifier IS :identifier" if conditions[:identifier]


    if group == :year
      Statistic.count(:group => "year(at_time)", :conditions => [condition_text, conditions]).each_pair do |year, count|
        results[DateTime.civil(year)] = count
      end
    else
      condition_text += " AND YEAR(statistics.at_time) =  :year"
      years = conditions[:start_date].year..conditions[:end_date].year
      years.each do |year|
        Statistic.count(:group => "#{group}(at_time)", :conditions => [condition_text, conditions.merge(:year => year)]).each_pair do |position, count|
          day_of_year = group == :week ? position.to_i.weeks : position.to_i.months

          results[DateTime.civil(year) + day_of_year] = count
        end
        
      end

      
    end

    results
  end
end
