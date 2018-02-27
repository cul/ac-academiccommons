class API < Grape::API
  version 'v1', using: :path
  prefix :api

  helpers SolrHelpers

  mount Search
  mount DataFeed
end
