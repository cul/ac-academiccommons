# frozen_string_literal: true

# List of frameworks that will be included in the sprockets asset pipeline if it is present
# These will be excluded from the asset pipeline
FRAMEWORKS_WITH_ASSETS = %w[actiontext trix actioncable activestorage].freeze

Rails.application.config.after_initialize do
  config = Rails.application.config

  # Remove framework asset directories from the asset pipeline paths list
  config.assets.paths.reject! do |path|
    FRAMEWORKS_WITH_ASSETS.any? { |dir| path.to_s.include? "/#{dir}/" }
  end
  puts '0000000000 the pathhhhhsss'
  puts config.assets.paths
  puts '0000000000'
end

# ToDO :
# maybe, we do not need this file...?
#
