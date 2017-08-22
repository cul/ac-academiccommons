require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')

namespace :ac do
  desc "FOR DEVELOPMENT ONLY: Adds an item to repository."
  task :populate_solr => :environment do
    Rake::Task["ci:load_collection"].invoke
    Rake::Task["ci:load_fixtures"].invoke

    index = AcademicCommons::Indexer.new
    index.items('actest:1', only_in_solr: false)
    index.close
  end

  desc "Adds notification entry for each item in the solr core"
  task :add_new_item_notification => :environment do
    rsolr = AcademicCommons::Utils.rsolr

    start, rows = 0, 100
    while true
      solr_params = {
        q: '*:*', start: start, rows: rows, fl: 'id,author_uni,handle',
        fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""],
        qt: 'standard'
      }

      docs = rsolr.get('select', params: solr_params)["response"]["docs"]

      break if docs.blank?

      docs.each do |d|
        d.fetch('author_uni', []).each do |uni|
          Notification.record_new_item_notification(d['handle'], nil, uni, true)
        end
      end

      start += rows
    end
  end
end
