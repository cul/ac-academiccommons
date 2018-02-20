require File.expand_path('../config/application', __FILE__)
require 'rake'

Rails.application.load_tasks

begin
  # configure the release versions of jettywrapper to use with CI
  require 'jettywrapper'
  JETTY_ZIP_BASENAME = 'hyacinth-fedora-3.8.1-no-solr'.freeze
  Jettywrapper.url = "https://github.com/cul/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

  require 'rspec/core/rake_task'

  task(:spec).clear # get rid of the default task

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--tag ~integration --tag ~type:feature'
  end

  RSpec::Core::RakeTask.new(:spec_all) do |t|
  end

  desc 'Start Solr'
  task :solr do
    puts "Unpacking and starting solr...\n"
    SolrWrapper.wrap do |solr_wrapper_instance|
      # Create collection
      solr_wrapper_instance.with_collection(name: 'test', dir: 'solr/conf') do |collection_name|
        puts 'I think Solr started hit space after you check:'
        sleep 1 while $stdin.getch != ' '
      end
      puts 'Stopping solr...'
    end
    puts 'Solr has been stopped.'
  end

  desc 'Run all tests regardless of tags'
  task :ci do
    Rake::Task['jetty:clean'].invoke

    jetty_params = Jettywrapper.load_config

    error = Jettywrapper.wrap(jetty_params) do
      SolrWrapper.wrap do |solr_wrapper_instance|
        solr_wrapper_instance.with_collection(name: 'test', dir: 'solr/conf') do |collection_name|
          system 'RAILS_ENV=test rake ac:populate_solr'
          Rake::Task['spec_all'].invoke
        end
      end
    end

    raise "test failures: #{error}" if error
  end
rescue LoadError
  # no rspec available
end
