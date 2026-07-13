# frozen_string_literal: true

class StatisticsSummary < ApplicationRecord
  validates :identifier, presence: true
  validates :event, presence: true
  validates :summary_month, presence: true

  validates :count,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  scope :for_event, ->(event) { where(event: event) }
  scope :for_month, ->(month) { where(summary_month: month.beginning_of_month) }

  def self.for_period(from, to)
    where(
      summary_month: from.beginning_of_month..to.beginning_of_month
    )
  end
end
