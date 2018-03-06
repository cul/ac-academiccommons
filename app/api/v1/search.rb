module V1
  class Search < Grape::API
    content_type :json, 'application/json'
    content_type :rss, 'application/rss+xml'
    formatter :rss, ->(object, env) {
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct! :xml, version: '1.0'
      xml.rss(version: '2.0', 'xmlns:dc': 'http://purl.org/dc/elements/1.1', 'xmlns:vivo': 'http://vivoweb.org/ontology/core') {
        xml.channel {
          xml.title('Academic Commons Search Results')
          xml.link(
            env['rack.url_scheme'] + '://' + env['HTTP_HOST'] + env['ORIGINAL_FULLPATH']
          )
          xml.description('Academic Commons Search Results')
          xml.language('en-us')

          object.value_for(:records).each do |doc|
            xml.item do
              xml.title doc.value_for(:title)
              xml.link doc.value_for(:persistent_url)

              xml.tag!('dc:creator', doc.value_for(:author).join('; ')) if doc.value_for(:author).present?

              xml.guid doc.value_for(:persistent_url)
              xml.pubDate doc.value_for(:created_at) #.rfc822
              xml.tag!('dc:date', doc.value_for(:date))    if doc.value_for(:date).present?
              xml.description doc.value_for(:abstract) if doc.value_for(:abstract).present?

              xml.tag!('dc:subject', doc.value_for(:subject).join(', '))         if doc.value_for(:subject).present?
              xml.tag!('dc:type', doc.value_for(:type).join(', '))       if doc.value_for(:type).present?
              xml.tag!('vivo:Department', doc.value_for(:department).join(', ')) if doc.value_for(:department).present?
            end
          end
        }
      }
    }

    default_format :json

    params do
      optional :search_type, coerce: Symbol, default: :keyword,     values: V1::Helpers::Solr::SEARCH_TYPES,
                             desc: 'type of search to be conducted, in most cases a keyword search should be sufficient'
      optional :q,           type: String, desc: 'query string'
      optional :page,        type: Integer,  default: 1,            values: ->(v) { v.positive? }, desc: 'page number'
      optional :per_page,    type: Integer,  default: 25,           values: 1..100, desc: 'number of results returned per page; the maximum number of results is 100'
      optional :sort,        coerce: Symbol, default: :best_match,  values: V1::Helpers::Solr::SORT, desc: 'sorting of search results'
      optional :order,       coerce: Symbol, default: :desc,        values: V1::Helpers::Solr::ORDER, desc: 'ordering of results'

      Helpers::Solr::FILTERS.each do |filter|
        optional filter, type: Array[String],  documentation: { desc: "#{filter} filter", param_type: 'query' }
      end
    end

    desc 'Query to conduct searches through all Academic Commons records',
      success: { code: 202, message: 'successful response' },
      failure: [
        { code: 400, message: 'invalid parameters'}
      ],
      produces: ['application/json', 'application/rss+xml']
    get :search do
      solr_response = query_solr(params: params)
      present solr_response, with: Entities::SearchResponse, params: params
    end
  end
end
