# frozen_string_literal: true

# Enable resque tasks and ensure that setup and work tasks have access to the environment
require 'resque/tasks'
task 'resque:setup' => :environment
task 'resque:work' => :environment

MAX_WAIT_TIME_TO_KILL_WORKERS = 120
PIDFILE_PATH = 'tmp/pids'

namespace :resque do
  desc 'Stop current workers and start new workers'
  task restart_workers: :environment do
    Rake::Task['resque:stop_workers'].invoke
    Rake::Task['resque:start_workers'].invoke
  end

  desc 'Stop running workers'
  task stop_workers: :environment do
    stop_workers
  end

  desc 'Start workers'
  task start_workers: :environment do
    start_workers(Rails.application.config_for(:resque))
  end

  def store_pids(pids)
    pids_to_store = pids
    pids_to_store.each_with_index do |pid_to_store, index|
      pid_storage_file = "#{PIDFILE_PATH}/resque_work_#{index + 1}.pid"
      File.write(File.expand_path(pid_storage_file, Rails.root), "#{pid_to_store}\n")
    end
  end

  def clear_pid_files
    pid_files = Dir.glob(File.join(PIDFILE_PATH, 'resque_work*.pid')).select { |path|
      File.file?(path) && !File.zero?(path)
    }
    pid_files.each do |pidfile|
      File.delete(pidfile)
    end
  end

  def read_pids
    pid_files = Dir.glob(File.join(PIDFILE_PATH, 'resque_work*.pid')).select { |path|
      File.file?(path) && !File.zero?(path)
    }

    pid_files.map do |file_path|
      File.open(file_path, &:gets).chomp
    end
  end

  def stop_workers
    pids = read_pids

    if pids.empty?
      puts 'No known workers to kill.'
    else
      # First tell workers to stop accepting new work by sending USR2 signal
      puts "\nTelling workers to finish current jobs, but not process any new jobs..."
      syscmd = "kill -s USR2 #{pids.join(' ')}"
      puts "$ #{syscmd}"
      `#{syscmd}`
      puts "\n"
      puts 'Waiting for workers to finish current jobs...'
      start_time = Time.zone.now
      while (Time.zone.now - start_time) < MAX_WAIT_TIME_TO_KILL_WORKERS
        sleep 1
        num_workers_working = Resque.workers.count(&:working?)
        puts "#{num_workers_working} workers still working..."
        break if num_workers_working.zero?
      end
      puts "\n"
      if Resque.workers.count(&:working?).positive?
        puts "Workers are still running, but wait time of #{MAX_WAIT_TIME_TO_KILL_WORKERS} has been exceeded. Sending QUIT signal anyway."
      else
        puts 'Workers are no longer processing any jobs. Safely sending QUIT signal...'
      end
      syscmd = "kill -s QUIT #{pids.join(' ')}"
      puts "$ #{syscmd}"
      `#{syscmd}`
      clear_pid_files
      puts "\n"
      puts 'Workers have been shut down.'
    end

    # Unregister old workers
    Resque.workers.each(&:unregister_worker)
  end

  # Start a worker with proper env vars and output redirection
  def start_workers(resque_config)
    polling_interval = resque_config[:polling_interval]
    worker_config = resque_config.fetch(:workers, {})
    total_workers = 0
    worker_info_string = worker_config.map { |queues, count|
      total_workers += count
      "  [ #{queues} ] => #{count} #{count == 1 ? 'worker' : 'workers'}"
    }.join("\n")
    puts "Starting #{total_workers} #{total_workers == 1 ? 'worker' : 'workers'} with a polling interval of #{polling_interval} seconds:\n" + worker_info_string

    ops = {
      pgroup: true,
      err: [Rails.root.join('log', 'resque.log').to_s, 'a'],
      out: [Rails.root.join('log', 'resque.log').to_s, 'a']
    }

    pids = []
    worker_config.each do |queues, count|
      env_vars = {
        'QUEUES' => queues.to_s,
        'RAILS_ENV' => Rails.env.to_s,
        'INTERVAL' => polling_interval.to_s # jobs tend to run for a while, so a 5-second checking interval (the default) is fine
      }
      count.times do
        # Using Kernel.spawn and Process.detach because regular system() call would
        # cause the processes to quit when capistrano finishes.
        pid = spawn(env_vars, 'rake resque:work', ops)
        Process.detach(pid)
        pids << pid
      end
    end

    store_pids(pids)
  end
end
