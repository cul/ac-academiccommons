# frozen_string_literal: true

module Statistics
  class Pruner
    BATCH_SIZE = 10_000

    def self.call(...)
      new(...).call
    end

    def initialize(to_date: nil)
      @to_date = to_date || (checkpoint.processed_until - 1.year)

      validate_year_before_checkpoint!
    end

    def call
      Statistic.where(at_time: ...to_date)
               .find_in_batches(batch_size: BATCH_SIZE)
               .sum do |batch|
        Statistic.where(id: batch.map(&:id)).delete_all
      end
    end

    private

    attr_reader :to_date

    def checkpoint
      @checkpoint ||= StatisticsSummaryCheckpoint.current
    end

    def validate_year_before_checkpoint!
      cutoff_time = checkpoint.processed_until - 1.year
      return unless to_date > cutoff_time

      raise ArgumentError,
            'to date must be at least 1 year older than the checkpoint'
    end
  end
end
