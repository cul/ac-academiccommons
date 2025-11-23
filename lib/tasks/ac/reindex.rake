namespace :ac do
  namespace :reindex do
    desc 'Reindex all items and assets'
    task all: :environment do
      index = AcademicCommons::Indexer.new(verbose: true)
      index.all_items
      index.close
    end

    desc 'Reindex items by pids'
    task by_item_pid: :environment do
      if ENV['pids']
        pids = ENV['pids'].split(',')
      else
        puts Rainbow('Incorrect arguments. Pass pids=pid:1,pid:2').red
      end

      if pids.present?
        index = AcademicCommons::Indexer.new(verbose: true)
        index.items(*pids)
        index.close
      end
    end

    desc 'Reindex by pid (item or asset)'
    task by_pid: :environment do
      if ENV['use_fedora_config_file'].present?
        # This allows us to override the fedora config file in case we want to use a different Fedora instance
        config_file_path = ENV['use_fedora_config_file']
        puts "Since use_fedora_config_file is present, overriding fedora.yml with file: #{config_file_path}"
        ActiveFedora.init({ fedora_config_path: config_file_path })
      end

      if ENV['pidlist'].present? || ENV['pids'].present?
        pids = open(ENV['pidlist']).map(&:strip!) if ENV['pidlist'].present?
        pids = ENV['pids'].split(',')             if ENV['pids'].present?

        index = AcademicCommons::Indexer.new(verbose: true)
        index.by_pids(pids)
        index.close
      else
        puts Rainbow('Incorrect arguments. Pass pidlist=/path/to/file').red
      end
    end
  end
end
