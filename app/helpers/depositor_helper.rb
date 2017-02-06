require "ac_indexing"

module DepositorHelper
  AC_COLLECTION_NAME = 'collection:3'

  def process_indexing(params)
    logger.info "==== started ingest function ==="

    if(params[:cancel])
      existing_time_id = existing_ingest_time_id(params[:cancel])
      if(existing_time_id)
        Process.kill "KILL", params[:cancel].to_i
        File.delete("#{Rails.root}/tmp/#{params[:cancel]}.index.pid")
        log_file = File.open("#{Rails.root}/log/ac-indexing/#{existing_time_id}.log", "a")
        log_file.write("CANCELLED")
        log_file.close
        flash.now[:notice] = "Ingest has been cancelled"
      else
        flash.now[:notice] = "Oh, um, we can't find the process ID #{params[:cancel]}, so we can't cancel it.  It's probably my fault, so I'm really sorry about that."
      end
    end

    # set time
    time = Time.new
    time_id = time.strftime("%Y%m%d-%H%M%S")
    @existing_ingest_pid = nil
    @existing_ingest_time_id = nil

    # clean up temp pid files for indexing runs
    Dir.glob("#{Rails.root}/tmp/*.index.pid") do |tmp_pid_file|
      first_namepart, *rest_namepart = File.basename(tmp_pid_file).split(/\./)
      @existing_ingest_time_id = existing_ingest_time_id(first_namepart)
      if(@existing_ingest_time_id == nil)
        File.delete(tmp_pid_file)
      else
        @existing_ingest_pid = first_namepart
      end
    end

    if(params[:commit] == "Commit" && @existing_ingest_time_id.nil? && !params[:cancel])
      collection = params[:collections].to_s.strip
      unless collection.blank? || (collection == AC_COLLECTION_NAME)
        flash.now[:notice] = "#{collection} is not a collection used by Academic Commons."
        return
      end

      items = params[:items] ? params[:items].gsub(/ /, ";") : ""

      @existing_ingest_pid = Process.fork do
        logger.info "==== STARTED INDEXING ==="

        begin
          indexing_results = ACIndexing::reindex(
            {
              :collections => collection,
              :items => items,
              :overwrite => params[:overwrite],
              :metadata => params[:metadata],
              :fulltext => params[:fulltext],
              :delete_removed => params[:delete_removed],
              :time_id => time_id,
              :executed_by => params[:executed_by] || current_user.uid
            }
          )

          logger.info "===== FINISHED INDEXING, STARTING TO SEND NOTIFICATIONS ==="

          if(params[:notify])
            Notifier.reindexing_results(indexing_results[:errors].size.to_s, indexing_results[:indexed_count].to_s, indexing_results[:new_items].size.to_s, time_id).deliver
          end

          AcademicCommons::NotifyDepositors.of_new_items(indexing_results[:new_items])
          expire_fragment('repository_statistics')
        rescue => e
          logger.fatal "Error Indexing: #{e.message}"
          logger.fatal e.backtrace.join("\n ")
        end
      end

      Process.detach(@existing_ingest_pid)
      @existing_ingest_time_id = time_id.to_s

      logger.info "Started ingest with PID: #{@existing_ingest_pid} (#{@existing_ingest_time_id})"

      tmp_pid_file = File.new("#{Rails.root}/tmp/#{@existing_ingest_pid}.index.pid", "w+")
      tmp_pid_file.write(@existing_ingest_time_id)
      tmp_pid_file.close
    end
  end

  def existing_ingest_time_id(pid)
    if(pid_exists?(pid))
      running_tmp_pid_file = File.open("#{Rails.root}/tmp/#{pid}.index.pid")
      return running_tmp_pid_file.gets
    end
  end

  def pid_exists?(pid)
    `ps -p #{pid}`.include?(pid)
  end
end
