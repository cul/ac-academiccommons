module V1
  class Record < Grape::API
    content_type :json, 'application/json'
    default_format :json

    helpers do
      def get_document(doi)
        response = AcademicCommons.search do |params|
          params.aggregators_with_assets
          params.id(doi)
          params.rows(1)
        end
        response.docs.first
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
        error! 'Record not found', 404
      else
        present record, with: Entities::FullRecord
      end
    end
  end
end
