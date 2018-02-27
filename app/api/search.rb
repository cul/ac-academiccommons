class Search < Grape::API
  content_type :json, 'application/json'
  content_type :rss, 'application/rss+xml'
  formatter :rss, ->(object, env) {
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: '1.0'
    xml.rss(version: '2.0', 'xmlns:dc': 'http://purl.org/dc/elements/1.1', 'xmlns:vivo': 'http://vivoweb.org/ontology/core') {
      xml.channel {
        xml.title('Academic Commons Search Results')
        # xml.link(search_action_url(params))
        xml.description('Academic Commons Search Results')
        xml.language('en-us')

        object.value_for(:records).each do |doc|
          xml.item do
            xml.title doc[:title] if doc.key?(:title)
            xml.link doc[:persistent_url]

            xml.tag!('dc:creator', doc[:author].join('; ')) if doc.key?(:author)

            xml.guid doc[:identifier]          if doc.key?(:identifier)
            xml.pubDate doc[:created_at] #.rfc822
            xml.tag!('dc:date', doc[:date])    if doc.key?(:date)
            xml.description doc[:description]  if doc.key?(:description)

            xml.tag!('dc:subject', doc[:subject].join(', '))         if doc.key?(:subject)
            xml.tag!('dc:type', doc[:content_type].join(', '))       if doc.key?(:content_type)
            xml.tag!('vivo:Department', doc[:department].join(', ')) if doc.key?(:department)
          end
        end
      }
    }
  }

  default_format :json

  params do
    optional :search_type, values: SolrHelpers::SEARCH_TYPES, default: 'keyword'
    optional :q
    optional :page,     type: Integer, default: 1#, values: 1...
    optional :per_page, type: Integer, default: 25,   values: 1..100
    optional :sort,     default: 'best_match', values: SolrHelpers::SORT
    optional :order,    default: 'desc', values: SolrHelpers::ORDER

    SolrHelpers::FILTERS.each do |filter|
      optional filter, type: Array[String]
    end
  end

  desc 'Conduct searches through all Academic Commons records'
  get '/search(/:search_type)' do
    solr_response = query_solr(params: params)
    present solr_response, with: Entities::SearchResponse, params: params
  end
end
