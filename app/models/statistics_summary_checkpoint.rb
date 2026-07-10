class StatisticsSummaryCheckpoint < ApplicationRecord
  validates :processed_until, presence: true

  class << self
    def current
      first_or_create!(processed_until: Time.at(0).utc)
    end
  end

  def advance_to!(time)
    update!(processed_until: time)
  end
end
