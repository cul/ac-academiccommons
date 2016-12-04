require "item_class"
require "ac_indexing"

module DepositorHelper
  AC_COLLECTION_NAME = 'collection:3'

  def notify_depositors_embargoed_item_added(pids)
    depositors = prepare_depositors_to_notify(pids)

    logger.info "====== Notifying Depositors of New Embargoed Item ======"

    depositors.each do |depositor|
      logger.info "=== Notifying #{depositor.name}(#{depositor.uni}) at #{depositor.email} ==="

      depositor.items_list.each do |item|
        logger.info "\tFor #{item.title}, PID: #{item.pid}, Persistent URL: #{item.handle}"
      end

      Notifier.depositor_embargoed_notification(depositor).deliver_now
    end
  end

  def notify_depositors_item_added(pids)
    depositors = prepare_depositors_to_notify(pids)

    logger.info "====== Notifing Depositors of New Item ======"

    # Loops through each depositor and notifies them for each new item now available.
    depositors.each do |depositor|
      logger.info "=== Notifying #{depositor.name}(#{depositor.uni}) at #{depositor.email} ==="

      depositor.items_list.each do |item|
        logger.info "\tFor #{item.title}, PID: #{item.pid}, Persistent URL: #{item.handle}"
      end

      Notifier.depositor_first_time_indexed_notification(depositor).deliver_now
    end
  end

  def prepare_depositors_to_notify(pids)
    depositors_to_notify = Hash.new

    pids.each do | pid |
      logger.debug "=== Processing Depositors for Record: #{pid}"

      item = get_item(pid)

      logger.debug "=== item created for pid: #{pid}"
      logger.debug "title: #{item.title}, handle: #{item.handle}, num of authors: #{item.authors_uni.size}"

      item.authors_uni.each do | uni |

        logger.info "=== process uni: #{uni} depositor for pid: #{pid}"

        if(!depositors_to_notify.key?(uni))
          depositor = AcademicCommons::LDAP.find_by_uni(uni)
          depositor.items_list = []
          depositors_to_notify.store(uni, depositor)
        end

        depositor = depositors_to_notify[uni]
        depositor.items_list << item

        logger.info "=== process uni: #{uni} depositor for pid: #{pid} === finished"
      end
    end

    logger.info "====== depositors_to_notify.size: #{depositors_to_notify.size}"

    return depositors_to_notify.values
  end

  def process_indexing(params)
    logger.info "==== started ingest function ==="

    params.each do |key, value|
      logger.info "param: #{key} - #{value}"
    end

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
        logger.info "==== started indexing ==="

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

        logger.info "===== finished indexing, starting notifications part ==="

        if(params[:notify])
          Notifier.reindexing_results(indexing_results[:errors].size.to_s, indexing_results[:indexed_count].to_s, indexing_results[:new_items].size.to_s, time_id).deliver
        end

        notify_depositors_item_added(indexing_results[:new_items])
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

  def get_item(pid)
    # Can probably just use the object returned by blacklight, solr document struct of some sort.
    result = Blacklight.default_index.search(:fl => 'author_uni,id,handle,title_display,free_to_read_start_date', :fq => "pid:\"#{pid}\"")["response"]["docs"]

    item = Item.new
    item.pid = result.first[:id]
    item.title = result.first[:title_display]
    item.handle = result.first[:handle]
    item.free_to_read_start_date = result.first[:free_to_read_start_date]

    item.authors_uni = []

    if(result.first[:author_uni] != nil)
      # item.authors_uni = result.first[:author_uni] || []
      item.authors_uni = fix_authors_array(result.first[:author_uni])
    end

    return item
  end

  def fix_authors_array(authors_uni)
    author_unis_clean = []

    authors_uni.each do | uni_str |
      author_unis_clean.push(uni_str.split(', '))
    end

    return author_unis_clean.flatten
  end
end
