class ACIndexing

  def self.delete_index
    indexing_log = ActiveSupport::Logger.new(STDOUT)
    indexing_log.info "Deleting Solr index..."
    rsolr.delete_by_query("*:*")
    rsolr.commit
    indexing_log.close
  end

  def self.delete_pid(pid)
    indexing_log = ActiveSupport::Logger.new(STDOUT)
    indexing_log.info "delete: #{pid}"
    rsolr.delete_by_id(pid)
    rsolr.commit
    indexing_log.info "Deleting Solr index for: (#{pid}) - success"
    indexing_log.close
  end

  def self.log_removed
    indexing_log = ActiveSupport::Logger.new(STDOUT)

    indexing_log.info "Fedora URL: " + Rails.application.config_for(:fedora)['url']
    indexing_log.info "Solr URL: " + Rails.application.config_for(:solr)['url']

    ac_collection = ActiveFedora::Base.find("collection:3")
    member_pids = ac_collection.list_members(true)

    indexing_log.info "Checking against " + member_pids.length.to_s + " items in Fedora..."

    indexing_log.info removed_objects(member_pids)
    indexing_log.close
  end

  def self.object_indexed?(pid)
    !rsolr.find(filters: {id: "\"#{pid}\""})["response"]["docs"].empty?
  end

  def self.object_exists?(pid)
    rubydora = ActiveFedora::Base.connection_for_pid(pid)
    rubydora.client[object_url(pid, query_options)].head.status == 200
  rescue Exception => exception
    reindex_logger.error(exception)
    return false
  end

  def self.rsolr
    @rsolr ||= begin
      url = Rails.application.config.solr['url']
      RSolr.connect(:url => url)
    end
  end

  def self.reindex(options = {})
    start_time = Time.new

    collections = options.delete(:collections)
    items = options.delete(:items)
    # skip isn't being passed in to this function in any implementation, but it accepts an array of PIDs to ignore
    # should we want to implement it anywhere at any time
    skip = options.delete(:skip) || nil
    overwrite = as_boolean(options.delete(:overwrite))
    metadata = as_boolean(options.delete(:metadata))
    fulltext = as_boolean(options.delete(:fulltext))
    delete_removed = as_boolean(options.delete(:delete_removed))
    log_level = options.delete(:log_level) || Logger::INFO
    time_id = options.delete(:time_id) || Time.new.strftime("%Y%m%d-%H%M%S")
    init_logger(log_level, time_id)

    executed_by = options.delete(:executed_by) || "UNKNOWN USER"

    reindex_logger.info "This re-index executed by: #{executed_by}"
    reindex_logger.info "Collections: " + (collections || "(none)")
    reindex_logger.info "Items: " + (items || "(none)")
    reindex_logger.info "Overwrite existing?: " + overwrite.to_s
    reindex_logger.info "Index metadata?: " + metadata.to_s
    reindex_logger.info "Index full text?: " + fulltext.to_s
    reindex_logger.info "Delete items removed from Fedora?: " + delete_removed.to_s

    reindex_logger.info "Fedora URL: " + Rails.application.config_for(:fedora)['url']
    reindex_logger.info "Solr URL: "   + Rails.application.config_for(:solr)['url']

    if(collections)
      collections = collections.split(";")
      collections = collections.collect { |pid| ActiveFedora::Base.find(pid) }
    end

    if(items)
      items = items.split(";")
    else
      items = []
    end

    if(skip)
      skip = skip.split(";")
    else
      skip = []
    end

    ## TEMP -- need to set temporary array of items to ignore until we can actually "remove" them from Fedora
    ignore_file = File.open(File.dirname(__FILE__) + "/ac_indexing_ignore") or die "Unable to open ignore file..."
    ignore = []
    ignore_file.each_line { |line| ignore.push line.strip }

    # Build up an ignore query, so we can remove anything in the ignore file from the index
    reindex_logger.info "Removing any items from the index that we're supposed to ignore..."
    ignore_item_delete_queries = []
    reindex_logger.debug ignore.inspect
    ignore.each { |ignore_item| ignore_item_delete_queries.push 'id:' + ignore_item.gsub(/:/, "\\:") }
    ignore_item_delete_queries.in_groups_of(100, false).each do |group|
      group_delete_query = group.join(' OR ')
      rsolr.delete_by_query(group_delete_query)
    end

    solr_params = {
      :collections => collections,
      :items => items, :format => "ac2",
      :fulltext => fulltext,
      :metadata => metadata,
      :delete_removed => delete_removed,
      :overwrite => overwrite, :ignore => ignore, :skip => skip
    }

    if collections
      collections.each do |collection|
        collection.list_members(true).each { |pid| items << pid }
      end
    end

    items.uniq!
    items.sort!
# --- adapting from Solr.ingest
    items_not_in_solr = []
    new_items = []
    doc_statuses = Hash.new { |h,k| h[k] = [] }
    errors = []

    if delete_removed == true
      delete_removed_objects(items)
    end

    reindex_logger.info "Preparing to index " + items.length.to_s + " items..."

    items.each do |item|
      if(ignore.index(item).nil? == false || skip.index(item).nil? == false)
        reindex_logger.info "Ignoring/skipping " + item + "..."
        doc_statuses[:skipped] << item
        next
      end

      if object_indexed?(item)
        unless overwrite == true
          doc_statuses[:skipped] << item
          next
        end
      else
        items_not_in_solr << item
      end

      reindex_logger.info "Indexing #{item}..."

      begin
        i = ActiveFedora::Base.find(item)
        i.update_index
        i.list_members.each do |resource|
          reindex_logger.info("indexing resource: ")
          reindex_logger.info(resource.to_solr)
          resource.update_index
        end
        doc_statuses[:success] << item
        if(items_not_in_solr.include? i.pid)
          new_items << i.pid
        end
      rescue Exception => e
        reindex_logger.error e.message
        doc_statuses[:error] << item
        next
      end
    end

    reindex_logger.info "Committing changes to Solr..."
    rsolr.commit

    indexed_count = doc_statuses[:success].length
    errors = doc_statuses[:error]
    results = {:results => doc_statuses, :errors => errors, :indexed_count => indexed_count, :new_items => new_items}

    reindex_logger.info "FINISHED WITH THE FOLLOWING RESULTS: \n#{results.inspect}"

    seconds_spent = Time.new - start_time
    readable_time_spent = Time.at(seconds_spent).utc.strftime("%H hours, %M minutes, %S seconds")

    reindex_logger.info "Time spent: " + readable_time_spent
    reindex_logger.close

    return results
  end

  def self.reindex_logger
    @reindex_logger
  end

  def self.init_logger(log_level, time_id)
    filepath = File.join(Rails.root, 'log', 'ac-indexing', "#{time_id}.log")
    @reindex_logger = ActiveSupport::Logger.new(filepath)
    @reindex_logger.level = log_level
    @reindex_logger.formatter = Rails.application.config.log_formatter
    @reindex_logger
  end

  def self.delete_removed_objects(fedora_item_pids = [])
    reindex_logger.info "Deleting items removed from Fedora..."
    removed_objects(fedora_item_pids).each do |id|
      reindex_logger.info "Deleting " + id + "..."
      rsolr.delete_by_query("id:" + id.to_s.gsub(/:/,'\\:'))
    end

    rsolr.commit
  end

  def self.removed_objects(fedora_item_pids = [])
    start = 0
    rows = 500
    removed = []
    results = rsolr.select({:q => "", :fl => "id", :start => start, :rows => rows})
    reindex_logger.info "Identifying items removed from Fedora..."
    while(!results["response"]["docs"].empty?)
      reindex_logger.info("Checking Solr index from #{start} to #{(start + rows)}...")
      results["response"]["docs"].each do |doc|

        if(fedora_item_pids.nil?)
          if(!object_exists?(doc["id"]))
            reindex_logger.info "Noting item removed from fedora:  #{doc["id"]}..."
            removed << doc["id"].to_s
          end
        else
          if(!fedora_item_pids.include?(doc["id"].to_s))
            reindex_logger.info "Noting removed item #{doc["id"]}..."
            removed << doc["id"].to_s
          end
        end
      end

      start = start + rows
      results = rsolr.get 'select', :params => {:q => "", :fl => "id", :start => start, :rows => rows}
    end
    return removed
  end

  def self.as_boolean(value)
    if(value.nil?)
      return false
    end
    return [true, "true", 1, "1", "T", "t"].include?(value.class == String ? value.downcase : value)
  end
end
