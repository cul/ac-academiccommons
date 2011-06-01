require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')
require File.expand_path(File.dirname(__FILE__) + '../../../config/initializers/load_configs.rb')

namespace :ac do
  
  desc "Runs a re-index of particular item(s) and/or collection(s)"
  task :reindex, [:collections, :items, :overwrite, :metadata, :fulltext, :delete_removed] => :environment do |t, args|
    
    overwrite = as_boolean(args[:overwrite])
    metadata = as_boolean(args[:metadata])
    fulltext = as_boolean(args[:fulltext])
    delete_removed = as_boolean(args[:delete_removed])
    
    $stdout.puts "environment: " + (RAILS_ENV || "(not set)")
    $stdout.puts "collections: " + (args[:collections] || "(not set)")
    $stdout.puts "items: " + (args[:items] || "(not set)")
    $stdout.puts "overwrite?: " + overwrite.to_s
    $stdout.puts "metadata?: " + metadata.to_s 
    $stdout.puts "fulltext?: " + fulltext.to_s
    $stdout.puts "delete_removed?: " + delete_removed.to_s
    
    solr_configs = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    solr_config = {}
    solr_config[:url] = solr_configs[RAILS_ENV]['url']
    
    fedora_server = Cul::Fedora::Server.new(FEDORA_CONFIG)
    solr_server = Cul::Fedora::Solr.new(solr_config)

    $stdout.puts "Fedora: " + fedora_server.inspect
    $stdout.puts "Solr: " + solr_server.inspect

    collections = args[:collections].split(";")      
    collections = collections.collect { |pid| fedora_server.item(pid) }
    
    if(!args[:items].nil?)
      items = args[:items].split(";")
      items = items.collect { |pid| fedora_server.item(pid) }
    end

    ## TEMP -- need to set temporary array of items to ignore until we can actually "remove" them from Fedora
    ignore_file = File.open(File.dirname(__FILE__) + "/ignore") or die "Unable to open ignore file..."
    ignore = []
    ignore_file.each_line { |line| ignore.push line.strip }
    
    # Build up an ignore query, so we can remove anything in the ignore file from the index
    $stdout.puts "Removing any items from the index that we're supposed to ignore..."
    ignore_item_delete_queries = []
    ignore.each { |ignore_item| ignore_item_delete_queries.push 'id:' + ignore_item.gsub(/:/, "\\:") }
    ignore_item_delete_queries.in_groups_of(100, false).each do |group|
      
      group_delete_query = group.join(' OR ')
      solr_server.rsolr.delete_by_query(group_delete_query)
      
    end

    solr_params = {:items => items, :format => "ac2", :fedora_server => fedora_server, :collections => collections, :fulltext => fulltext, :metadata => metadata, :delete_removed => delete_removed, :overwrite => overwrite, :ignore => ignore, :skip => nil, :process => nil}
    results = solr_server.ingest(solr_params)
    
    # Let's just do a final commit to ensure everything gets pushed
    solr_server.rsolr.commit
    
    $stdout.puts results.inspect
    
  end
  
end

def as_boolean(value)
  if(value.nil?) 
    return false
  end
  return [true, "true", 1, "1", "T", "t"].include?(value.class == String ? value.downcase : value)
end
