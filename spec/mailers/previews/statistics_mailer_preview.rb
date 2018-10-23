class StatisticsMailerPreview < ActionMailer::Preview
  def usage_statistics
    usage_stats = AcademicCommons::Metrics::UsageStatistics.new.calculate_lifetime

    StatisticsMailer.usage_statistics(
      'example@example.com',
      'Usage Statistics for Center of Unicorns',
      "Dear Researcher, \n\n Below you will find the usage statistics we talked about. \n\nThanks,\n\nCarla",
      usage_stats.lifetime_csv,
      usage_stats,
      :lifetime
    )
  end
end
