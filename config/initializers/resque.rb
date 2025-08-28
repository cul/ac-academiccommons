rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'
config_file = rails_root + '/config/resque.yml'

if rails_env == 'academiccommons_prod' || rails_env == 'academiccommons_test'
  resque_config = YAML::load(ERB.new(IO.read(config_file)).result, aliases: true)
  Resque.redis = resque_config[rails_env]['url']
end
