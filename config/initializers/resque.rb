rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'
config_file = rails_root + '/config/resque.yml'

if ['academiccommons_prod', 'academiccommons_staging', 'academiccommons_semantic_beta',
    'academiccommons_test'].include?(rails_env)
  resque_config = YAML::load(ERB.new(IO.read(config_file)).result, aliases: true)
  Resque.redis = resque_config[rails_env]
end
