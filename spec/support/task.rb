# Taken from https://www.eliotsykes.com/test-rails-rake-tasks-with-rspec
#
# Class to be used when testing rake tasks. Loads rake task in test environment
# and automatically adds task-specific methods to tests when type: :task.
#

require 'rake'

# Task names should be used in the top-level describe, with an optional
# "rake "-prefix for better documentation.
module TaskExampleGroup
  extend ActiveSupport::Concern

  included do
    # Make the Rake task available as `task` in your examples:
    subject(:task) { tasks[task_name] }

    let(:task_name) { self.class.top_level_description.sub(/\Arake /, '') }
    let(:tasks) { Rake::Task }
  end
end

RSpec.configure do |config|
  # Tag Rake specs with `:task` metadata or put them in the spec/tasks dir
  config.define_derived_metadata(file_path: %r{/spec/tasks/}) do |metadata|
    metadata[:type] = :task
  end

  config.include TaskExampleGroup, type: :task

  config.before(:suite) do
    Rails.application.load_tasks
  end
end
