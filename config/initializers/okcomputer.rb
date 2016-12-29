# Additional checks for OkComputer.

# Checking Solr connection
OkComputer::Registry.register(
  'solr', OkComputer::SolrCheck.new(Rails.application.config_for(:solr)['url'])
)
OkComputer::Registry.register(
  'blacklight_solr', OkComputer::SolrCheck.new(Rails.application.config_for(:blacklight)['url'])
)

# Checking Fedora connection

# Checking mail server configuration and availability
OkComputer::Registry.register('action_mailer', OkComputer::ActionMailerCheck.new)

# Check that directories exists
OkComputer::Registry.register('indexing_log_directory', OkComputer::DirectoryCheck.new('log/ac-indexing'))
OkComputer::Registry.register('reports_log_directory', OkComputer::DirectoryCheck.new('log/monthly_reports'))
OkComputer::Registry.register('self_deposits_directory', OkComputer::DirectoryCheck.new('data/self-deposit-uploads'))
