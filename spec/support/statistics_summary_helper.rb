module StatisticsSummaryHelper
  def rebuild_statistics_summary!
    StatisticsSummary.delete_all
    at_time = Statistic.minimum(:at_time) || Time.current

    checkpoint = StatisticsSummaryCheckpoint.find_or_create_by!(id: 1) do |cp|
        cp.processed_until = at_time
    end

    checkpoint.update!(processed_until: at_time)

    Statistics::Updater.call(
      from: at_time,
      to: Time.current
    )
  end
end

RSpec.configure do |config|
config.include StatisticsSummaryHelper
end
