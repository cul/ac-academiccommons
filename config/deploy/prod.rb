# Resque configuration for test
role :resque_worker, "ac-rails-#{fetch(:stage)}1.cul.columbia.edu"
role :resque_scheduler, "ac-rails-#{fetch(:stage)}1.cul.columbia.edu"

set :workers, YAML.load_file(File.expand_path('../../resque.yml', __FILE__), aliases: true)[fetch(:stage).to_s]['workers']

# We default to storing PID files in a tmp/pids folder in your shared path.
# set :resque_pid_path, -> { File.join(shared_path, 'tmp', 'pids') }

# Give workers access to the Rails environment
set :resque_environment_task, true

set :resque_log_file, 'log/resque.log'

# Adding resque config to list of linked files
set :linked_files, fetch(:linked_files, []).push('config/resque.yml')

after 'deploy:restart', 'resque:restart'


server "ac-rails-#{fetch(:stage)}1.cul.columbia.edu", user: fetch(:remote_user), roles: %w(app db web)
# In test/prod, deploy from release tags; most recent version is default
ask :branch, proc { `git tag --sort=version:refname`.split("\n").last }
