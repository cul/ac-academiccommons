require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')
require File.expand_path(File.dirname(__FILE__) + '../../../config/initializers/load_configs.rb')

require "rubygems"
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora.rb')
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora/item.rb')
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora/server.rb')
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora/solr.rb')

namespace :ac do
  
  desc "Runs a re-index of particular item(s) and/or collection(s)"
  task :reindex, [:collections, :items, :fulltext] do |t, args|
    
    solr_configs = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    solr_config = {}
    solr_config[:url] = solr_configs[RAILS_ENV]['url']
    
    fedora_server = Cul::Fedora::Server.new(FEDORA_CONFIG)
    solr_server = Cul::Fedora::Solr.new(solr_config)

    #solr_server.delete_index

    collections = args[:collections].split(";")      
    collections = collections.collect { |pid| fedora_server.item(pid) }
    
    if(!args[:items].nil?)
      items = args[:items].split(";")
      items = items.collect { |pid| fedora_server.item(pid) }
    end

    #item = fedora_server.item("ac:125467") 
    #solr_params = {:items => [item], :format => "ac2", :collections => nil, :fulltext => args[:fulltext] || false, :metadata => true, :overwrite => true, :skip => nil, :process => nil}
    solr_params = {:items => items, :format => "ac2", :collections => collections, :fulltext => args[:fulltext] || false, :metadata => true, :overwrite => true, :skip => nil, :process => nil}
    results = solr_server.ingest(solr_params)
    
    puts results.inspect
    
  end
  
end
