require File.expand_path(File.dirname(__FILE__) + '../../../lib/james_monkeys.rb')

namespace :ac do
  desc "Adds item and collection to the repository."
  task :populate_solr => :environment do
    Rake::Task["load:fixtures"].invoke

    item = ActiveFedora::Base.find('actest:1')
    tries = 0
    while((length = item.list_members(true).length) == 0 && tries < 50) do
      puts "(actest:1).list_members was zero, waiting for buffer to flush"
      sleep(1)
      tries += 1
    end
    raise "Never found item members, check Solr" if (tries > 50)

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
        start: start, rows: rows, fl: 'id,author_uni_ssim,cul_doi_ssi',
        fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""],
        qt: 'search'
      }

      docs = rsolr.get('select', params: solr_params)["response"]["docs"]

      break if docs.blank?

      docs.each do |d|
        d.fetch('author_uni_ssim', []).each do |uni|
          Notification.record_new_item_notification(d['cul_doi_ssi'], nil, uni, true)
        end
      end

      start += rows
    end
  end
end
