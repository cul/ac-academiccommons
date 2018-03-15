namespace :ac do
  namespace :reindex do
    desc 'Reindex all items and assets'
    task all: :environment do
      index = AcademicCommons::Indexer.new(verbose: true)
      index.all_items
      index.close

      Rails.cache.delete('repository_statistics')
    end

    desc 'Reindex items by pids'
    task by_pid: :environment do
      if ENV['pids']
        pids = ENV['pids'].split(',')
      else
        puts Rainbow('Incorrect arguments. Pass pids=pid:1,pid:2').red
      end

      if pids.present?
        index = AcademicCommons::Indexer.new(verbose: true)
        index.items(*pids)
        index.close

        Rails.cache.delete('repository_statistics')
      end
    end
  end
end
