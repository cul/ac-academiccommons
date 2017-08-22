namespace :duplicate_records do
  desc 'Removes solr document'
  task :delete_solr_document, [:pid] => :environment do |t, args|
    rsolr = AcademicCommons::Utils.rsolr
    rsolr.delete_by_id(args[:pid])
    rsolr.commit
  end

  desc 'Merges statistics for a set of aggregator or asset'
  task :merge_stats, [:pid, :duplicate_pid] => :environment do |t, args|
    pid, duplicate_pid = args[:pid], args[:duplicate_pid]

    puts ""

    duplicate_document = ActiveFedora::SolrService.query("{!raw f=id}#{duplicate_pid}").first
    puts Rainbow("Duplicate pid (#{duplicate_pid})").yellow
    puts "active_fedora_model_ssi: #{duplicate_document['active_fedora_model_ssi']}"
    puts "number of stats: #{Statistic.where(identifier: duplicate_pid).count}"

    puts Rainbow("\nWill be merged with...\n").magenta

    document = ActiveFedora::SolrService.query("{!raw f=id}#{pid}").first
    puts Rainbow("Pid (#{pid}):").cyan
    puts "active_fedora_model_ssi: #{document['active_fedora_model_ssi']}"
    puts "number of stats: #{Statistic.where(identifier: pid).count}"

    puts Rainbow("\nAre you sure you want to merge these records' statistics? (y/n)").red
    input = STDIN.gets.strip
    if input == 'y'
      puts Rainbow("Merging statistics...").green
      Statistic.merge_stats(args[:pid], args[:duplicate_pid])
      puts "#{duplicate_pid} (duplicate) has #{Statistic.where(identifier: duplicate_pid).count} stats."
      puts "#{pid} has #{Statistic.where(identifier: pid).count} stats."
    else
      puts Rainbow("Statistics merge aborted").red
    end
  end
end
