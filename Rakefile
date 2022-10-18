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

  # Note: Don't include Rails environment for this task, since enviroment includes a check for the presence of database.yml
  task :config_files do
    # yml templates
    Dir.glob(Rails.root.join("config", "*.template.yml")).each do |template_yml_path|
      target_yml_path = Rails.root.join('config', File.basename(template_yml_path).sub(".template.yml", ".yml"))
      next if File.exist?(target_yml_path)
      FileUtils.touch(target_yml_path) # Create if it doesn't exist
      target_yml = YAML.load_file(target_yml_path) || YAML.load_file(template_yml_path)
      File.open(target_yml_path, 'w') { |f| f.write target_yml.to_yaml }
    end
    Dir.glob(Rails.root.join("config", "*.template.yml.erb")).each do |template_yml_path|
      target_yml_path = Rails.root.join('config', File.basename(template_yml_path).sub(".template.yml.erb", ".yml"))
      next if File.exist?(target_yml_path)
      FileUtils.touch(target_yml_path) # Create if it doesn't exist
      target_yml = YAML.load_file(target_yml_path) || YAML.safe_load(ERB.new(File.read(template_yml_path)).result(binding), aliases: true)
      File.open(target_yml_path, 'w') { |f| f.write target_yml.to_yaml }
    end
  end

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
  task ci: [:config_files, 'jetty:clean'] do
    ENV['RAILS_ENV'] = 'test'
    Rails.env = ENV['RAILS_ENV']

    error = Jettywrapper.wrap(Jettywrapper.load_config) do
      solr_wrapper_config = Rails.application.config_for(:solr_wrapper).deep_symbolize_keys
      if File.exist?(solr_wrapper_config[:instance_dir])
        # Delete old solr if it exists because we want a fresh solr instance
        puts "Deleting old test solr instance at #{solr_wrapper_config[:instance_dir]}...\n"
        FileUtils.rm_rf(solr_wrapper_config[:instance_dir])
      end
      SolrWrapper.wrap(solr_wrapper_config) do |solr_wrapper_instance|
        # Create collections
        # create is stricter about solr options being in [c,d,n,p,shards,replicationFactor]
        original_solr_options = solr_wrapper_instance.config.static_config.options[:solr_options].dup
        solr_wrapper_instance.config.static_config.options[:solr_options]&.slice!(:c, :d, :n, :p, :shards, :replicationFactor)
        solr_wrapper_config[:collection].each { |c| solr_wrapper_instance.create(c) }
        solr_wrapper_instance.config.static_config.options[:solr_options] = original_solr_options
        begin
          system 'RAILS_ENV=test rake ac:populate_solr'
          Rake::Task['spec_all'].invoke
        rescue SystemExit => e
          print "ignoring rspec system exit signal: #{e.message}"
        end

        print 'Stopping solr...'
      end
      puts 'stopped.'
    end

    raise "test failures: #{error}" if error
  end

  task default: [:rubocop, :ci]
rescue LoadError
  puts 'No jettywrapper, rspec or rubocop available.'
  puts 'This is expected in production environments.'
end
