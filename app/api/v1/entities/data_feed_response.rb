module V1
  module Entities
    class DataFeedResponse < Grape::Entity
      expose :total_number_of_results do |solr_response, _options|
        solr_response.dig('response', 'numFound')
      end

      expose :page_number do |_solr_response, options|
        options[:params][:page]
      end

      expose :per_page do |_solr_response, options|
        options[:params][:per_page]
      end

      expose :records, using: FullRecord do |solr_response, _options|
        solr_response.docs
      end
    end
  end
end
