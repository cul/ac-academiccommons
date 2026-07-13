# frozen_string_literal: true

module Statistics
  class Updater
    def self.call(...)
      new(...).call
    end

    def initialize(from: nil, to: nil, prune_before: nil)
      @from = from
      @to = to
      @prune_before = prune_before
    end

    def call
      checkpoint = StatisticsSummaryCheckpoint.fetch!

      from = @from || checkpoint.processed_until
      to   = @to || default_to

      raise ArgumentError, 'from must be before to' if from >= to

      result = nil

      ApplicationRecord.transaction do
        result = Statistics::SummaryRollup.call(
          from: from,
          to: to
        )

        Statistics::SummaryVerifier.call(result)

        checkpoint.advance_to!(to)

        Statistics::Pruner.call(
          before: prune_before || default_prune_before
        )
      end

      result
    end

    private

    attr_reader :prune_before

    def default_to
      1.day.ago.end_of_day
    end

    def default_prune_before
      1.year.ago.beginning_of_day
    end
  end
end
