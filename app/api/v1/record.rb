module V1
  class Record < Grape::API
    content_type :json, 'application/json'
    default_format :json

    helpers do
      def get_document(doi)
        connection = AcademicCommons::Utils.rsolr
        solr_parameters = {
          rows: 1,
          fq: [
            "cul_doi_ssi:\"#{doi}\"",
            "has_model_ssim:\"#{ContentAggregator.to_class_uri}\"",
          ],
          fl: '*', # default blacklight solr param
          qt: 'search' # default blacklight solr param
        }
        solr_response = connection.get('select', params: solr_parameters)
        solr_response['response']['docs'].first
      rescue StandardError
        error! 'unexpected error', 500
      end
    end

    params do
      requires :doi
    end

    desc 'Retrieves full record'
    get '/record/doi/:doi', requirements: { doi: /10[.].*/i } do
      record = get_document(params[:doi])
      if record.blank?
        error! "Record not found", 404
      else
        present SolrDocument.new(record).to_semantic_values, with: Entities::FullRecord
      end
    end
  end
end
