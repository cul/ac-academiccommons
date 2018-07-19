require File.expand_path('../config/application', __FILE__)
require 'rake'

require 'resque/tasks'
task 'resque:setup' => :environment

Rails.application.load_tasks

begin
  require 'jettywrapper'
  JETTY_ZIP_BASENAME = 'hyacinth-fedora-3.8.1-no-solr'.freeze
  Jettywrapper.url = "https://github.com/cul/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

  # RSpec rake tasks
  require 'rspec/core/rake_task'
  task(:default).clear
  task(:spec).clear # get rid of the default task

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--tag ~integration --tag ~type:feature'
  end

  RSpec::Core::RakeTask.new(:spec_all) do |t|
  end

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  desc 'Start Solr'
  task :solr do
    puts "Unpacking and starting solr...\n"
    SolrWrapper.wrap do |solr_wrapper_instance|
      # Create collection
      solr_wrapper_instance.with_collection(name: 'test', dir: 'solr/conf') do
        puts 'I think Solr started hit space after you check:'
        sleep 1 while $stdin.getch != ' '
      end
      puts 'Stopping solr...'
    end
    puts 'Solr has been stopped.'
  end

  desc 'Run all tests regardless of tags'
  task ci: ['jetty:clean'] do
    jetty_params = Jettywrapper.load_config

    error = Jettywrapper.wrap(jetty_params) do
      SolrWrapper.wrap do |solr_wrapper_instance|
        solr_wrapper_instance.with_collection(name: 'test', dir: 'solr/conf') do
          system 'RAILS_ENV=test rake ac:populate_solr'
          Rake::Task['spec_all'].invoke
        end
      end
    end

    raise "test failures: #{error}" if error
  end

  task default: [:rubocop, :ci]
rescue LoadError
  puts 'No jettywrapper, rspec or rubocop avaiable.'
  puts 'This is expected in production environments.'
end
