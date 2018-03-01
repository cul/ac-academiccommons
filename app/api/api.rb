require 'grape-swagger'

class API < Grape::API
  # Adding CORS headers.
  before do
    header['Access-Control-Allow-Origin'] = '*'
    header['Access-Control-Request-Method'] = '*'
  end

  prefix :api
  version 'v1', using: :path

  helpers V1::Helpers::Solr

  mount V1::Search
  mount V1::DataFeed

  add_swagger_documentation \
    info: {
      title: "Academic Commons API"
    }
end