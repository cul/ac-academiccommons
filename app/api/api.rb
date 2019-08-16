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
  mount V1::Record

  Grape::Middleware::Auth::Strategies.add(:http_token, Auth::Token)

  add_swagger_documentation \
    info: {
      title: 'Academic Commons API v1',
      description: 'This api provides the ability to query for Academic Commons '\
                   'records. `/search` results are limited to 100 results per page '\
                   'and only show the most commonly used fields. The `/record` '\
                   'endpoint will display all the fields. Frequent consumers '\
                   'of this api may be interested in setting up a `data_feed/` endpoint'\
                   'for their specific purposes. Data feeds require authentication '\
                   '(via HTTP Token Authentication), but have the benefit of '\
                   'displaying the entire record and not having an upper limit '\
                   'on the number of results displayed.'\
                   "\n\n All endpoints accept `format` as a query parameter to "\
                   'specify format response instead of accept headers. For example: `format=json`.'\
                   "\n\n Records return a list of `resource_paths`. `resource_paths` are partial "\
                   'paths that can be used to create a file download link. Preprend the base url '\
                   'listed above to the paths in order to generate download links.',
      contact_name: 'Academic Commons Staff',
      contact_email: 'ac@columbia.edu'
    },
    tags: [
      { name: 'search', description: 'Search for records' },
      { name: 'data_feed', description: 'Returns non-paginated subset of records' },
      { name: 'record', description: 'Returns full record' }
    ],
    array_use_braces: true
end
