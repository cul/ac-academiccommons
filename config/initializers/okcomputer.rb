# Additional checks for OkComputer.

# Require authentication to all checks but the default check
creds = Rails.application.config_for(:secrets)['okcomputer']
raise 'Missing OkComputer credentials' if creds.blank?

OkComputer.require_authentication(creds['user'], creds['password'], except: %w(default))

# Checking Solr connection
solr_urls = [:solr, :blacklight].map { |c| Rails.application.config_for(c)['url'] }.uniq
solr_urls.each_with_index do |url, i|
  OkComputer::Registry.register("solr#{i}", OkComputer::SolrCheck.new(url))
end

# Checking Fedora connection
OkComputer::Registry.register('fedora', OkComputer::FedoraCheck.new)

# Checking mail server configuration and availability
OkComputer::Registry.register('action_mailer', OkComputer::ActionMailerCheck.new)

# Check that directories exists
OkComputer::Registry.register('indexing_log_directory', OkComputer::DirectoryCheck.new('log/ac-indexing'))
OkComputer::Registry.register('reports_log_directory', OkComputer::DirectoryCheck.new('log/monthly_reports'))
OkComputer::Registry.register('storage_directory', OkComputer::DirectoryCheck.new('storage'))

# Check sitemap exists
url = URI.join(Rails.application.config.default_host, '/sitemap.xml.gz')
OkComputer::Registry.register('sitemap', OkComputer::HttpCheck.new(url.to_s))

# Check that resque/redis is up and working
if Rails.application.config.active_job.queue_adapter == :resque
  OkComputer::Registry.register('redis', OkComputer::RedisCheck.new(Rails.application.config_for(:resque)))
  OkComputer::Registry.register('resque', OkComputer::ResqueDownCheck.new)
end
