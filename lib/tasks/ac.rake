require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')

namespace :ac do
  desc "FOR DEVELOPMENT ONLY: Adds an item to repository."
  task :populate_solr => :environment do
    Rake::Task["ci:load_collection"].invoke
    Rake::Task["ci:load_fixtures"].invoke

    index = AcademicCommons::Indexer.new
    index.items('actest:1', only_in_solr: false)
    index.close
  end
end
