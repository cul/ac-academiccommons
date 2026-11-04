# frozen_string_literal: true

module Statistics
  class Updater
    IN_FLIGHT_REQUEST_BUFFER = 5.minutes

    def self.run(...)
      new(...).run
    end

    def initialize(before_date: nil)
      @before_date = before_date || (Time.current - IN_FLIGHT_REQUEST_BUFFER)

      return unless checkpoint.processed_until && @before_date <= checkpoint.processed_until

      raise ArgumentError, 'before_date must be after checkpoint'
    end

    def run
      ApplicationRecord.transaction do
        result = Statistics::SummaryRollup.run(before_date: before_date)

        Statistics::SummaryVerifier.run(result)

        checkpoint.advance_to!(before_date)

        result
      end
    end

    private

    attr_reader :before_date

    def checkpoint
      @checkpoint ||= StatisticsSummaryCheckpoint.current
    end
  end
end
