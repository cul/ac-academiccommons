require File.expand_path('../config/application', __FILE__)
require 'rake'

require 'resque/tasks'
task 'resque:setup' => :environment

Rails.application.load_tasks

begin
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
      target_yml = YAML.load_file(target_yml_path) || YAML.load_file(template_yml_path, aliases: true)
      File.open(target_yml_path, 'w') { |f| f.write target_yml.to_yaml }
    end
    Dir.glob(Rails.root.join("config", "*.template.yml.erb")).each do |template_yml_path|
      target_yml_path = Rails.root.join('config', File.basename(template_yml_path).sub(".template.yml.erb", ".yml"))
      next if File.exist?(target_yml_path)
      FileUtils.touch(target_yml_path) # Create if it doesn't exist
      target_yml = YAML.load_file(target_yml_path, aliases: true) || YAML.safe_load(ERB.new(File.read(template_yml_path)).result(binding), aliases: true)
      File.open(target_yml_path, 'w') { |f| f.write target_yml.to_yaml }
    end
    # docker yml templates
    Dir.glob(Rails.root.join("docker/templates", "*.yml")).each do |template_yml_path|
      target_yml_path = Rails.root.join('docker', File.basename(template_yml_path))
      next if File.exist?(target_yml_path)
      FileUtils.touch(target_yml_path) # Create if it doesn't exist
      target_yml = YAML.load_file(target_yml_path, aliases: true) || YAML.load_file(template_yml_path, aliases: true)
      File.open(target_yml_path, 'w') { |f| f.write target_yml.to_yaml }
    end
  end

  desc 'Run all tests regardless of tags'
  task ci: [:config_files] do
    ENV['RAILS_ENV'] = 'test'
    Rails.env = ENV['RAILS_ENV']
    rspec_system_exit_failure_exception = nil

    begin
      task_stack = ['docker_wrapper', 'ac:populate_solr', 'spec_all']
      Rake::Task[task_stack.shift].invoke(task_stack)
    rescue SystemExit => e
      rspec_system_exit_failure_exception = e
    end

    raise rspec_system_exit_failure_exception unless rspec_system_exit_failure_exception.nil?
  end

  task :docker_wrapper, [:task_stack] => [:environment] do |_task, args|
    unless Rails.env.test?
      raise 'This task should only be run in the test environment (because it clears docker volumes)'
    end

    task_stack = args[:task_stack]

    # stop docker if it's currently running (so we can delete any old volumes)
    Rake::Task['ac:docker:stop'].invoke
    # rake tasks must be re-enabled if you want to call them again later during the same run
    Rake::Task['ac:docker:stop'].reenable

    ENV['rails_env_confirmation'] = Rails.env # setting this to skip prompt in volume deletion task
    Rake::Task['ac:docker:delete_volumes'].invoke

    Rake::Task['ac:docker:start'].invoke
    begin
      Rake::Task[task_stack.shift].invoke(task_stack) while task_stack.present?
    rescue SystemExit => e
      rspec_system_exit_failure_exception = e
    end
    Rake::Task['ac:docker:stop'].invoke
    raise rspec_system_exit_failure_exception if rspec_system_exit_failure_exception
  end

  task default: [:rubocop, :ci]
rescue LoadError => e
  # Be prepared to rescue so that this rake file can exist in environments where RSpec is unavailable (i.e. production environments).
  puts '[Warning] Exception creating ci/rubocop/rspec rake tasks. '\
    'This message can be ignored in environments that intentionally do not pull in certain development/test environment gems (i.e. production environments).'
  puts e
end
