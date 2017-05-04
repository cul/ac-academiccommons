class Admin::IndexingController < ApplicationController
  before_filter :require_admin!

  # GET /admin/indexing
  def show
    if pid = index_running?
      @pid = pid
      @timestamp = log_timestamp(pid)
    end
  end

  # POST /admin/indexing
  # Performs an index of the items specificied.
  def create # collection or set of items
    if index_running?
      flash[:error] = "There is already an index process running. Please wait for the process to complete before starting a new one."
    else
      items = params[:items].split(/\s/)
      index_records(items: items, all: params[:all].eql?('true'))
    end

    redirect_to admin_indexing_url
  end

  # DELETE /admin/indexing
  # Cancels an ingest if there is one currently running.
  def destroy
    if pid = index_running?
      time_id = log_timestamp(pid)
      Process.kill "KILL", pid.to_i
      File.delete(pid_filepath(pid))
      log_file = File.open("#{Rails.root}/log/ac-indexing/#{time_id}.log", "a")
      log_file.write("CANCELLED")
      log_file.close
      flash[:notice] = "Index has been cancelled."
    else
      flash[:error] = "An index is not currently running."
    end

    redirect_to admin_indexing_url
  end

  # GET /admin/indexing/log_monitor/:timestamp
  # Returns the last n lines from the running process
  def log_monitor
    # if there is a tmp pid file, read in time from the pid file and display the last n lines of log
     raise "You must include the log ID" unless params[:timestamp]

     #constraint id to contain numbers and -

     log_path = "#{Rails.root}/log/ac-indexing/#{params[:timestamp]}.log"
     raise "Can't find log file #{params[:id]}.log" unless FileTest.exists?(log_path)

     log_content = `tail #{log_path}`

     respond_to do |format|
       format.html { render layout: false, text: '{ "log": ' + ActiveSupport::JSON.encode(log_content) + ' }' }
     end
  end

  private

  def index_records(items: [], all: false)
    return if items.blank? && !all

    time = Time.new
    time_id = time.strftime("%Y%m%d-%H%M%S")
    pid = nil

    pid = Process.fork do
      logger.info "==== STARTED INDEXING ===="

      begin
        index = AcademicCommons::Indexer.new(executed_by: current_user, start: time)
        index.all_items if all
        index.items(*items) unless items.blank?
        index.close

        logger.info "==== FINISHED INDEXING ===="
        expire_fragment('repository_statistics')
      rescue => e
        logger.fatal "Error Indexing: #{e.message}"
        logger.fatal e.backtrace.join("\n ")
      end
    end

    Process.detach(pid)

    logger.info "Started ingest with PID: #{pid} (#{time_id})"

    tmp_pid_file = File.new(pid_filepath(pid), "w+")
    tmp_pid_file.write(time_id)
    tmp_pid_file.close
  end

  def log_timestamp(pid)
    if pid_exists?(pid)
      running_tmp_pid_file = File.open(pid_filepath(pid))
      return running_tmp_pid_file.gets
    end
  end

  # Returns pid of process running or false if no process is running.
  def index_running?
    Dir.glob("#{Rails.root}/tmp/*.index.pid") do |tmp_pid_file|
      pid = File.basename(tmp_pid_file).split(/\./).first
      if pid_exists?(pid)
        return pid
      else
        File.delete(tmp_pid_file) # Clean up temp pid files from previous indexing runs.
      end
    end
    false
  end

  def pid_filepath(pid)
    File.join(Rails.root, 'tmp', "#{pid}.index.pid")
  end

  def pid_exists?(pid)
    Process.getpgid(pid.to_i)
    true
  rescue Errno::ESRCH
    false
  end
end
