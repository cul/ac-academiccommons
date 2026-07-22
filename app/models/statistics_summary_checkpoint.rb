# frozen_string_literal: true

class StatisticsSummaryCheckpoint < ApplicationRecord
  validates :processed_until, presence: true

  # There should only ever be one checkpoint row.
  def self.current
    find_or_create_by!(id: 1) do |checkpoint|
      checkpoint.processed_until = Time.at(0).utc
    end
  end

  def advance_to!(time)
    update!(processed_until: time)
  end
end
