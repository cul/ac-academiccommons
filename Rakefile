# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
unless File.exist?('config/database.yml')
  `cp config/database.template.yml config/database.yml`
end
unless File.exist?('config/fedora.yml')
  `cp config/fedora.template.yml config/fedora.yml`
end
unless File.exist?('config/solr.yml')
  `cp config/solr.template.yml config/solr.yml`
end

require File.expand_path('../config/application', __FILE__)
require 'rake'

AcademicCommons::Application.load_tasks

begin
  # configure the release versions of jettywrapper to use with CI
  require 'jettywrapper'
  JETTY_ZIP_BASENAME = 'hyacinth-fedora-3.8.1-no-solr'
  Jettywrapper.url = "https://github.com/cul/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

  require 'rspec/core/rake_task'

  task(:spec).clear # get rid of the default task

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = "--tag ~integration --tag ~type:feature"
  end
  RSpec::Core::RakeTask.new(:spec_all) do |t|
  end

  desc 'Start Solr'
  task :solr do
    puts "Unpacking and starting solr...\n"
    SolrWrapper.wrap({
    }) do |solr_wrapper_instance|
      # Create collection
      solr_wrapper_instance.with_collection(name: 'test', dir: 'solr/conf') do |collection_name|
        puts "I think Solr started hit space after you check:"
        sleep 1 while $stdin.getch != " "
      end
      puts 'Stopping solr...'
    end
    puts 'Solr has been stopped.'
  end
  desc 'Run all tests regardless of tags'
  task :ci do
    #TODO figure out how to get the indexer and the specs to run in the same environment
    raise "call with RAILS_ENV=test" unless Rails.env == 'test'
    Rake::Task["jetty:clean"].invoke
    jetty_params = Jettywrapper.load_config
    error = Jettywrapper.wrap(jetty_params) do
      puts "Unpacking and starting solr...\n"
      SolrWrapper.wrap({
      }) do |solr_wrapper_instance|
        # Create collection
        solr_wrapper_instance.with_collection(name: 'test', dir: 'solr/conf') do |collection_name|
          Rake::Task["ci:load_collection"].invoke
          Rake::Task["ci:load_fixtures"].invoke
          collection = ActiveFedora::Base.find('collection:3')
          tries = 0
          while((length = collection.list_members(true).length) == 0 && tries < 50) do
            puts "(collection:3).list_members was zero, waiting for buffer to flush"
            sleep(1)
            tries += 1
          end
          raise "Never found collection members, check Solr" if (tries > 50)
          Rake::Task["ac:reindex"].invoke('collection:3')
          Rake::Task["spec_all"].invoke
        end
        puts 'Stopping solr...'
      end
      puts 'Solr has been stopped.'
    end
    raise "test failures: #{error}" if error
  end
rescue LoadError
  # no rspec available
end
