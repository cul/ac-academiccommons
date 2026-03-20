class StatisticsSummary < ApplicationRecord
  validates :identifier, presence: true
  validates :event,      presence: true
  validates :year,       presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :month,      presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :count,      presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :identifier, uniqueness: { scope: [:event, :year, :month] }
  
  def self.increment!(identifier:, event:, year:, month:)
    record = find_or_create_by!(identifier: identifier, event: event, year: year, month: month) do |r|
        r.count = 0
    end

    self.where(id: record.id).update_all("count = count + 1")
    end

end