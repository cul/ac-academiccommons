# frozen_string_literal: true

# Enable resque tasks and ensure that setup and work tasks have access to the environment
require 'open3'
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

  def pid_files
    Dir.glob(File.join(PIDFILE_PATH, 'resque_work*.pid')).select { |path|
      File.file?(path) && !File.zero?(path)
    }
  end

  def clear_pid_files
    pid_files.each do |pidfile|
      File.delete(pidfile)
    end
  end

  def read_pids
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
    interval = polling_interval || '5'
    puts "Starting #{total_workers} #{total_workers == 1 ? 'worker' : 'workers'} with a polling interval of #{interval} seconds:\n" + worker_info_string
    err = Rails.root.join('log', 'resque.log').to_s
    out = Rails.root.join('log', 'resque.log').to_s
    rails_env = ENV['RAILS_ENV']

    worker_config.each do |queues, count|
      queues = queues.to_s
      count.times do |index|
        number = index + 1
        pidfile = Rails.root.join('tmp/pids/', "resque_work_#{number}.pid").to_s
        _stdout_str, _stderr_str, status = Open3.capture3("RAILS_ENV=#{rails_env}  QUEUE=\"#{queues}\"  PIDFILE=#{pidfile} BACKGROUND=yes VERBOSE=1 INTERVAL=#{interval} rake resque:work >> #{out} 2>> #{err}")
        puts "Worker #{number} started, status: #{status}"
      end
    end
  end
end
