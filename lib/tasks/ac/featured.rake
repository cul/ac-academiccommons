# frozen_string_literal: true
namespace :ac do
  namespace :featured do
    desc "Import a serialized featured search from a directory"
    task import: :environment do
      next unless ENV['DIR']
      FeaturedSearch.import(ENV['DIR'])
    end
    desc "Export a serialized featured search to a directory"
    task export: :environment do
      next unless ENV['SLUG']
      feature = FeaturedSearch.find_by(slug: ENV['SLUG'])
      feature.export(ENV['DIR'] || ENV['SLUG'])
    end
  end
end
