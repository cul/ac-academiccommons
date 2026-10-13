# frozen_string_literal: true

module Statistics
  class Updater
    IN_FLIGHT_REQUEST_BUFFER = 5.minutes

    def self.call(...)
      new(...).call
    end

    def initialize(to_date: nil)
      @to_date = to_date || (Time.current - IN_FLIGHT_REQUEST_BUFFER)

      return unless checkpoint.processed_until && @to_date <= checkpoint.processed_until

      raise ArgumentError, 'to date must be after checkpoint'
    end

    def call
      ApplicationRecord.transaction do
        result = Statistics::SummaryRollup.call(to_date: to_date)

        Statistics::SummaryVerifier.call(result)

        checkpoint.advance_to!(to_date)

        result
      end
    end

    private

    attr_reader :to_date

    def checkpoint
      @checkpoint ||= StatisticsSummaryCheckpoint.current
    end
  end
end
