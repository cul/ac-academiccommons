namespace :duplicate_records do
  desc 'Merges statistics for a set of aggregator or asset'
  task :merge_stats, [:pid, :duplicate_pid] => :environment do |t, args|
    Statistic.merge_stats(args[:pid], args[:duplicate_pid])
  end
end
