require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')
require File.expand_path(File.dirname(__FILE__) + '../../../config/initializers/load_configs.rb')

namespace :ac do
  
  require 'cul-fedora'
  
  desc "Runs a re-index of particular item(s) and/or collection(s)"
  task :reindex, [:environment, :collections, :items, :fulltext] do |t, args|
    
    $stdout.puts "environment: " + (args[:environment] || "")
    $stdout.puts "collections: " + (args[:collections] || "")
    $stdout.puts "items: " + (args[:items] || "")
    $stdout.puts "fulltext?: " + (args[:fulltext] || "")
    
    solr_configs = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    solr_config = {}
    solr_config[:url] = solr_configs[args[:environment]]['url']
    
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

    solr_params = {:items => items, :format => "ac2", :collections => collections, :ignore => ignore, :fulltext => args[:fulltext] || false, :metadata => true, :overwrite => true, :skip => nil, :process => nil}
    results = solr_server.ingest(solr_params)
    
    $stdout.puts results.inspect
    
  end
  
end
