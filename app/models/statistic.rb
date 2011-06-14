class Statistic < ActiveRecord::Base

  def self.reset_downloads
    Statistic.find_all_by_event("Download").each { |e| e.delete } 

    fedora_download_match = /^([\d\.]+).+\[([^\]]+)\].+download\/fedora_content\/\w+\/([^\/]+)/
    startdate = DateTime.parse("5/1/2011")

    count = 0
    File.open(File.join("tmp", "access.log")).each_with_index do |line, i|
      
      if (match = fedora_download_match.match(line))
        pid = match[3].gsub("%3A", ":")
        datetime = DateTime.parse(match[2].sub(":", " "))
        ip = match[1]

        if pid.include?("ac")
          Statistic.create!(:event => "Download", :ip_address => ip, :identifier => pid, :at_time => datetime)
        end
      end



    end

    puts count
  end
  
  # warning: MYSQL only
  def self.count_intervals(options = {})
    group = options[:group] || :month
    raise(ArgumentError, "invalid group parameter") unless group.in?(:month, :year, :week)



    results = Hash.arbitrary_depth
    conditions = {}

    events = (options[:event] || "show").listify

    conditions[:start_date] = options[:start_date] || Time.now - 6.months
    conditions[:end_date] = options[:end_date] || Time.now
    conditions[:identifier] = options[:identifier].listify

    events.each do |event|
      
      conditions[:event] = event

    condition_text = "statistics.at_time >= :start_date and  statistics.at_time <= :end_date AND statistics.event = :event"
    condition_text += " AND statistics.identifier IN (:identifier)" if conditions[:identifier]


    if group == :year
      Statistic.count(:group => "year(at_time)", :conditions => [condition_text, conditions]).each_pair do |year, count|
        results[event][DateTime.civil(year.to_i)] = count
      end
    else
      condition_text += " AND YEAR(statistics.at_time) =  :year"
      years = conditions[:start_date].year..conditions[:end_date].year
      years.each do |year|
        Statistic.count(:group => "#{group}(at_time)", :conditions => [condition_text, conditions.merge(:year => year)]).each_pair do |position, count|
          day_of_year = group == :week ? position.to_i.weeks : (position.to_i.months - 1)

          results[event][DateTime.civil(year) + day_of_year] = count
        end
        
      end

       
    end
    end
    results
  end
end
