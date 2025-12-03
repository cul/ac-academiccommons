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
    # t.rspec_opts = '--backtrace' # uncomment to print full backtrace on errors
  end

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  desc 'Run all tests regardless of tags'
  task :ci do
    ENV['RAILS_ENV'] = 'test'
    Rails.env = ENV['RAILS_ENV']
    ENV['skip_vector_embeddings_during_populate_solr'] = 'true'
    rspec_system_exit_failure_exception = nil

    begin
      task_stack = ['docker_wrapper', 'db:test:prepare', 'ac:populate_solr', 'spec_all']
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
