namespace :ac do
  desc "Adds item and collection to the repository."
  task :populate_solr => :environment do
    Rake::Task["load:fixtures"].invoke

    item = ActiveFedora::Base.find('actest:1')
    tries = 0

    while(item.list_members(true).length < 3 && tries < 50) do
      puts "(actest:1).list_members was less than 3, waiting for buffer to flush"
      sleep(1)
      tries += 1
    end
    raise "Never found item members, check Solr" if (tries > 50)

    index = AcademicCommons::Indexer.new
    index.items('actest:1', only_in_solr: false)
    index.close
  end
end
