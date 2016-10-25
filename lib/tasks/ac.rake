require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')
require File.expand_path(File.dirname(__FILE__) + '../../../lib/ac_indexing.rb')

namespace :ac do
  
  desc "Runs a re-index of particular item(s) and/or collection(s)"
  task :reindex, [:collections, :items, :overwrite, :metadata, :fulltext, :delete_removed] => :environment do |t, args|

    ACIndexing::reindex({
        :collections => args[:collections], 
        :items => args[:items],
        :overwrite => args[:overwrite] || 1, 
        :metadata => args[:metadata] || 1, 
        :fulltext => args[:fulltext], 
        :delete_removed => args[:delete_removed],
        :log_stdout => 1,
        :executed_by => "rake"
    })
    
  end
  
  task :deletepid, [:pid] => :environment do |t, args|

    
    ACIndexing::delete_pid(args[:pid])
    
  end
  
  task :deleteindex => :environment do
    
    ACIndexing::delete_index()
    
  end
  
  task :getremoved => :environment do
    
    ACIndexing::log_removed()
    
  end
end
