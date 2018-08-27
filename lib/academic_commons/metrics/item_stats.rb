module AcademicCommons
  module Metrics
    class ItemStats
      attr_reader :id, :document, :stats

      def initialize(document)
        @id = document.id
        @document = document
        @stats = { Statistic::VIEW => {}, Statistic::DOWNLOAD => {}, Statistic::STREAM => {} }
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

      # Dynamically defines method for each type of statistic: number_of_views,
      # number_of_streams, number_of_downloads.
      Statistic::EVENTS.each do |event|
        define_method :"number_of_#{event.downcase.pluralize}" do |time|
          get_stat(event, time)
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
end
