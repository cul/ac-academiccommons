module AcademicCommons::Statistics
  class ItemStats
    MONTH_KEY = '%b %Y'
    attr_reader :id, :document, :stats

    def initialize(document)
      @id = document[:id] || document['id']
      @document = document
      @stats = { Statistic::VIEW_EVENT => {}, Statistic::DOWNLOAD_EVENT => {}, Statistic::STREAM_EVENT => {} }
    end

    def get_stat(event, time='Period') # time can be Lifetime, Period, month-year
      unless /Lifetime|Period|\w{3} \d{4}/.match(time)
        # Mon year format can only be used if per_month is true
        raise 'time must be Lifetime, Period or Mon Year'
      end

      if @stats.key?(event) && @stats[event].key?(time)
        @stats[event][time]
      else
        raise "#{event} #{time} not part of stats. Check parameters."
      end
    end

    def add_stat(event, time, value)
      raise 'Not a valid event' unless Statistic.valid_event?(event)
      stats[event][time] = value
    end

    # return true if all the stats are 0
    def zero?
      @stats.values.map(&:values).flatten.sum.zero?
    end
  end
end
