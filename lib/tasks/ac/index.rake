namespace :ac do
  namespace :index do
    # Indexing jobs under this namespace will enqueue jobs to index items/assets,
    # instead of running them synchronously.
    desc 'Reindex all items and assets using worker queue'
    task all: :environment do
      puts 'pending implementation'
    end

    desc 'Reindex by pid (item or asset) using worker queue'
    task by_pid: :environment do
      if ENV['pidlist'].present? || ENV['pids'].present?
        pids = open(ENV['pidlist']).map(&:strip!) if ENV['pidlist'].present?
        pids = ENV['pids'].split(',')             if ENV['pids'].present?

        puts Rainbow("Preparing to index #{pids.size} item/assets").yellow

        pids.each do |pid|
          IndexingJob.perform_later(pid)
        end
      else
        puts Rainbow('Incorrect arguments. Pass pidlist=/path/to/file').red
      end
    end
  end
end
