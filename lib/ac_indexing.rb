require "stdout_logger"

# used for local testing of cul-fedora gem (comment out for normal deployment)
 require File.expand_path(File.dirname(__FILE__) + '../../lib/cul-fedora/item.rb')
 require File.expand_path(File.dirname(__FILE__) + '../../lib/cul-fedora/server.rb')
 require File.expand_path(File.dirname(__FILE__) + '../../lib/cul-fedora/solr.rb')

class ACIndexing
  
  def self.delete_index
    logger = Logger.new(STDOUT)
    logger.info "Deleting Solr index..."
    rsolr.delete_by_query("*:*")
    rsolr.commit
  end

  def self.delete_pid(pid)
    logger = Logger.new(STDOUT)

    logger.info "delete: " + pid
    rsolr.delete_by_id(pid)
    rsolr.commit
    logger.info "Deleting Solr index for: (" + pid + ") - success"
  end

  def self.log_removed
    logger = Logger.new(STDOUT)

    fedora_config = Rails.application.config.fedora
    fedora_config[:logger] = logger
    solr_config = Rails.application.config.solr
    solr_config[:logger] = logger

    logger.info "Fedora: " + fedora_config.inspect
    logger.info "Solr: " + solr_config.inspect

    ac_collection = ActiveFedora::Base.find("collection:3")
    member_pids = ac_collection.listMembers(true)

    logger.info "Checking against " + member_pids.length.to_s + " items in Fedora..."

    logger.info removed_objects(member_pids)
  end

  def self.object_indexed?(pid)
    !rsolr.find(filters: {id: "\"#{pid}\""})["response"]["docs"].empty?
  end

  def self.object_exists?(pid)
    rubydora = ActiveFedora::Base.connection_for_pid(pid)
    rubydora.client[object_url(pid, query_options)].head.status == 200
  rescue Exception => exception
    logger.error(exception)
    return false
  end

  def self.rsolr
    Rails.application.config.solr
    @rsolr ||= begin
      url = Rails.application.config.solr[:url]
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
    log_stdout = as_boolean(options.delete(:log_stdout))
    log_level = options.delete(:log_level) || Logger::INFO
    time_id = options.delete(:time_id) || Time.new.strftime("%Y%m%d-%H%M%S") 
    init_logger(log_stdout, log_level, time_id)

    executed_by = options.delete(:executed_by) || "UNKNOWN USER"

    logger.info "This re-index executed by: #{executed_by}"

    logger.info "Collections: " + (collections || "(none)")
    logger.info "Items: " + (items || "(none)")
    logger.info "Overwrite existing?: " + overwrite.to_s
    logger.info "Index metadata?: " + metadata.to_s
    logger.info "Index full text?: " + fulltext.to_s
    logger.info "Delete items removed from Fedora?: " + delete_removed.to_s
    logger.info "Logging to file and STDOUT?: " + log_stdout.to_s

    fedora_config = Rails.application.config.fedora
    fedora_config[:logger] = logger

    solr_config = Rails.application.config.solr
    solr_config[:logger] = logger

    logger.info "Fedora: " + fedora_config.inspect
    logger.info "Solr: " + solr_config.inspect

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
    logger.info "Removing any items from the index that we're supposed to ignore..."
    ignore_item_delete_queries = []
    logger.debug ignore.inspect
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
    collections.each do |collection|
      collection.listMembers(true).each { |pid| items << pid }
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

    logger.info "Preparing to index " + items.length.to_s + " items..."

    items.each do |item|
      if(ignore.index(item).nil? == false || skip.index(item).nil? == false)
        logger.info "Ignoring/skipping " + item + "..."
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

      logger.info "Indexing #{item}..."

      begin
        i = ActiveFedora::Base.find(item)
        i.update_index
        doc_statuses[:success] << item
        if(items_not_in_solr.include? i.pid)
          new_items << i.pid
        end
      rescue Exception => e
        logger.error e.message
        doc_statuses[:error] << item
        next
      end
    end

    logger.info "Committing changes to Solr..."
    rsolr.commit

    indexed_count = doc_statuses[:success].length
    errors = doc_statuses[:error]
    results = {:results => doc_statuses, :errors => errors, :indexed_count => indexed_count, :new_items => new_items}

    logger.info "FINISHED WITH THE FOLLOWING RESULTS: \n#{results.inspect}"

    seconds_spent = Time.new - start_time
    readable_time_spent = Time.at(seconds_spent).utc.strftime("%H hours, %M minutes, %S seconds")

    logger.info "Time spent: " + readable_time_spent

    return results
  end

  def self.logger
    @logger
  end

  def self.init_logger(log_stdout, log_level, time_id)
    if(log_stdout == true)
      @logger = StdOutLogger.new(File.dirname(__FILE__) + "/../log/ac-indexing/#{time_id}.log", $stdout)
    else
      @logger = Logger.new(File.dirname(__FILE__) + "/../log/ac-indexing/#{time_id}.log")
    end
    @logger.level = log_level
    @logger
  end

  def self.delete_removed_objects(fedora_item_pids = [])
    logger.info "Deleting items removed from Fedora..."
    removed_objects(fedora_item_pids).each do |id|
      logger.info "Deleting " + id + "..."
      rsolr.delete_by_query("id:" + id.to_s.gsub(/:/,'\\:'))
    end

    rsolr.commit
  end

  def self.removed_objects(fedora_item_pids = [])
    start = 0
    rows = 500
    removed = []
    results = rsolr.select({:q => "", :fl => "id", :start => start, :rows => rows})
    logger.info "Identifying items removed from Fedora..."
    while(!results["response"]["docs"].empty?)
      logger.info("Checking Solr index from #{start} to #{(start + rows)}...")
      results["response"]["docs"].each do |doc|

        if(fedora_item_pids.nil?)
          if(!object_exists?(doc["id"]))
            logger.info "Noting item removed from fedora:  #{doc["id"]}..."
            removed << doc["id"].to_s
          end
        else
          if(!fedora_item_pids.include?(doc["id"].to_s))
            logger.info "Noting removed item #{doc["id"]}..."
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