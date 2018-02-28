class API < Grape::API
  # Adding CORS headers.
  before do
    header['Access-Control-Allow-Origin'] = '*'
    header['Access-Control-Request-Method'] = '*'
  end

  version 'v1', using: :path
  prefix :api

  helpers SolrHelpers

  mount Search
  mount DataFeed
end
