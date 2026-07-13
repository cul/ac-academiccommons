# frozen_string_literal: true

module Statistics
  class Pruner
    DEFAULT_RETENTION_PERIOD = 1.year
    BATCH_SIZE = 10_000

    def self.call(...)
      new(...).call
    end

    def initialize(before: nil, from: nil, to: nil)
      @before = before
      @from = from
      @to = to

      validate_arguments!
    end

    def call
      delete_scope.find_in_batches(batch_size: BATCH_SIZE).sum do |batch|
        Statistic.where(id: batch.map(&:id)).delete_all
      end
    end

    private

    attr_reader :before, :from, :to

    def delete_scope
      if from && to
        Statistic.where(at_time: from...to)
      else
        Statistic.where(at_time: ...retention_cutoff)
      end
    end

    def retention_cutoff
      before || DEFAULT_RETENTION_PERIOD.ago
    end

    def validate_arguments!
      if before && (from || to)
        raise ArgumentError,
              'Specify either before or from/to, not both'
      end

      if (from && !to) || (!from && to)
        raise ArgumentError,
              'from and to must be provided together'
      end

      return unless from && to && from >= to

      raise ArgumentError,
            'from must be before to'
    end
  end
end
