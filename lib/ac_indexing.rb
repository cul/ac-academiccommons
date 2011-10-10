require "stdout_logger"

# used for local testing of cul-fedora gem (comment out for normal deployment)
# require File.expand_path(File.dirname(__FILE__) + '../../lib/cul-fedora/item.rb')
# require File.expand_path(File.dirname(__FILE__) + '../../lib/cul-fedora/server.rb')
# require File.expand_path(File.dirname(__FILE__) + '../../lib/cul-fedora/solr.rb')

class ACIndexing
  
  def self.deleteindex
    
    solr_config = SOLR_CONFIG
    solr_server = Cul::Fedora::Solr.new(solr_config)
    solr_server.delete_index()
    
  end
  
  def self.getremoved
    
    logger = Logger.new(STDOUT)
    
    fedora_config = FEDORA_CONFIG
    fedora_config[:logger] = logger
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    solr_config = SOLR_CONFIG
    solr_config[:logger] = logger
    solr_server = Cul::Fedora::Solr.new(solr_config)
    
    logger.info "Fedora: " + fedora_server.inspect
    logger.info "Solr: " + solr_server.inspect
    
    ac_collection = fedora_server.item("collection:3")
    members = ac_collection.listMembers
    member_pids = []
    members.each do |member|
      member_pids << member.pid
    end
    
    logger.info "Checking against " + member_pids.length.to_s + " items in Fedora..."
    
    logger.info solr_server.identify_removed(fedora_server, member_pids)
    
  end
  
  def self.reindex(options = {})
    
    collections = options.delete(:collections)
    items = options.delete(:items)
    overwrite = as_boolean(options.delete(:overwrite))
    metadata = as_boolean(options.delete(:metadata))
    fulltext = as_boolean(options.delete(:fulltext))
    delete_removed = as_boolean(options.delete(:delete_removed))
    log_stdout = as_boolean(options.delete(:log_stdout))
    log_level = options.delete(:log_level) || Logger::INFO
    time_id = options.delete(:time_id) || Time.new.strftime("%Y%m%d-%H%M%S") 
    executed_by = options.delete(:executed_by) || "UNKNOWN USER"

    if(log_stdout == true)
      logger = StdOutLogger.new(File.dirname(__FILE__) + "/../log/ac-indexing/#{time_id}.log", $stdout)
    else
      logger = Logger.new(File.dirname(__FILE__) + "/../log/ac-indexing/#{time_id}.log")
    end
    logger.level = log_level

    logger.info "This re-index executed by: #{executed_by}"

    logger.info "Collections: " + (collections || "(none)")
    logger.info "Items: " + (items || "(none)")
    logger.info "Overwrite existing?: " + overwrite.to_s
    logger.info "Index metadata?: " + metadata.to_s
    logger.info "Index full text?: " + fulltext.to_s
    logger.info "Delete items removed from Fedora?: " + delete_removed.to_s
    logger.info "Logging to file and STDOUT?: " + log_stdout.to_s
    
    fedora_config = FEDORA_CONFIG
    fedora_config[:logger] = logger
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    
    solr_config = SOLR_CONFIG
    solr_config[:logger] = logger
    solr_server = Cul::Fedora::Solr.new(solr_config)
    
    logger.info "Fedora: " + fedora_server.inspect
    logger.info "Solr: " + solr_server.inspect
    
    if(collections)
      collections = collections.split(";")      
      collections = collections.collect { |pid| fedora_server.item(pid) }
    end
    
    if(items)
      items = items.split(";")
      items = items.collect { |pid| fedora_server.item(pid) }
    end
    
    ## TEMP -- need to set temporary array of items to ignore until we can actually "remove" them from Fedora
    ignore_file = File.open(File.dirname(__FILE__) + "/tasks/ignore") or die "Unable to open ignore file..."
    ignore = []
    ignore_file.each_line { |line| ignore.push line.strip }
    
    # Build up an ignore query, so we can remove anything in the ignore file from the index
    logger.info "Removing any items from the index that we're supposed to ignore..."
    ignore_item_delete_queries = []
    logger.debug ignore.inspect
    ignore.each { |ignore_item| ignore_item_delete_queries.push 'id:' + ignore_item.gsub(/:/, "\\:") }
    ignore_item_delete_queries.in_groups_of(100, false).each do |group|
      
      group_delete_query = group.join(' OR ')
      solr_server.rsolr.delete_by_query(group_delete_query)
      
    end
    
    solr_params = {:items => items, :format => "ac2", :fedora_server => fedora_server, :collections => collections, :fulltext => fulltext, :metadata => metadata, :delete_removed => delete_removed, :overwrite => overwrite, :ignore => ignore, :skip => nil, :process => nil}
    results = solr_server.ingest(solr_params)
    
    # Let's just do a final commit to ensure everything gets pushed
    solr_server.rsolr.commit
    
    logger.info "FINISHED WITH THE FOLLOWING RESULTS:"
    logger.info results.inspect

    return results
    
  end
  
end

def as_boolean(value)
  if(value.nil?) 
    return false
  end
  return [true, "true", 1, "1", "T", "t"].include?(value.class == String ? value.downcase : value)
end
