require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')
require File.expand_path(File.dirname(__FILE__) + '../../../config/initializers/load_configs.rb')

require "rubygems"
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora.rb')
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora/item.rb')
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora/server.rb')
load File.expand_path(File.dirname(__FILE__) + '../../../../cul-fedora/lib/cul-fedora/solr.rb')

namespace :ac do
  
  desc "Runs a re-index of particular item(s) and/or collection(s)"
  task :reindex, [:items, :collections] do |t, args|
    
    solr_configs = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    solr_config = {}
    solr_config[:url] = solr_configs[RAILS_ENV]['url']
    
    fedora_server = Cul::Fedora::Server.new(FEDORA_CONFIG)
    solr_server = Cul::Fedora::Solr.new(solr_config)

    #item = fedora_server.item("ac:125467")
    collection = fedora_server.item("ac:20") 
    solr_params = {:items => nil, :format => "ac2", :collections => [collection], :fulltext => false, :metadata => true, :overwrite => true, :skip => nil, :process => nil}
    #solr_params = {:items => [item], :format => "ac2", :collections => nil, :fulltext => 0, :metadata => 1, :overwrite => 1, :skip => nil, :process => nil}
    results = solr_server.ingest(solr_params)
    
    puts results.inspect
    
  end
  
end
