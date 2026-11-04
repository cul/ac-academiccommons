# frozen_string_literal: true

module Statistics
  class Pruner
    BATCH_SIZE = 10_000

    def self.run(...)
      new(...).run
    end

    def initialize(before_date: nil)
      @before_date = before_date || (checkpoint.processed_until - 1.year)

      validate_year_before_checkpoint!
    end

    def run
      Statistic.where(at_time: ...before_date)
               .find_in_batches(batch_size: BATCH_SIZE)
               .sum do |batch|
        Statistic.where(id: batch.map(&:id)).delete_all
      end
    end

    private

    attr_reader :before_date

    def checkpoint
      @checkpoint ||= StatisticsSummaryCheckpoint.current
    end

    def validate_year_before_checkpoint!
      cutoff_time = checkpoint.processed_until - 1.year
      return unless before_date > cutoff_time

      raise ArgumentError,
            'before_date must be at least 1 year older than the checkpoint'
    end
  end
end
