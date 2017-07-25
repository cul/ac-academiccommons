namespace :duplicate_records do
  desc 'Removes solr document'
  task :delete_solr_document, [:pid] => :environment do |t, args|
    rsolr = RSolr.connect(url: Rails.application.config.solr['url'])
    rsolr.delete_by_id(args[:pid])
    rsolr.commit
  end

  desc 'Merges statistics for a set of aggregator or asset'
  task :merge_stats, [:pid, :duplicate_pid] => :environment do |t, args|
    Statistic.merge_stats(args[:pid], args[:duplicate_pid])
  end
end
