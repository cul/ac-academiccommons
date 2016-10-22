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
  JETTY_ZIP_BASENAME = 'fedora-3.8.1-with-risearch'
  Jettywrapper.url = "https://github.com/cul/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

  require 'rspec/core/rake_task'

  task(:spec).clear # get rid of the default task

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = "--tag ~type:integration --tag ~type:feature"
  end
  RSpec::Core::RakeTask.new(:spec_all) do |t|
  end

  desc 'Copy the Solr config over'
  task :configure_jetty => :environment do
    ['jetty/solr/development-core/conf','jetty/solr/test-core/conf'].each do |conf|
      FileUtils.rm_r conf
      FileUtils.cp_r 'solr/conf', conf
    end
  end

  desc 'Run all tests regardless of tags'
  task :ci do
    #TODO figure out how to get the indexer and the specs to run in the same environment
    raise "call with RAILS_ENV=test" unless Rails.env == 'test'
    Rake::Task["jetty:clean"].invoke
    Rake::Task["configure_jetty"].invoke
    jetty_params = Jettywrapper.load_config
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["ci:load_collection"].invoke
      Rake::Task["ci:load_fixtures"].invoke
      collection = Cul::Fedora::Item.new(:pid=>'collection:3', :server_config => Rails.application.config.fedora)
      tries = 0
      while((length = collection.list_members.length) == 0 && tries < 50) do
        puts "(collection:3).list_members was zero, waiting for buffer to flush"
        sleep(1)
        tries += 1
      end
      raise "Never found collection members, check Solr" if (tries > 50)
      Rake::Task["ac:reindex"].invoke('collection:3')
      Rake::Task["spec_all"].invoke
    end
    raise "test failures: #{error}" if error
  end
rescue LoadError
  # no rspec available
end
