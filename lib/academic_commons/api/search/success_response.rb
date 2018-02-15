require 'rss'

module AcademicCommons::API
  class Search
    class SuccessResponse < Response
      def initialize(parameters, solr_response: nil)
        @parameters = parameters
        @solr_response = solr_response

        body = send("#{@parameters[:format]}_body")
        headers = [] # need to generate link headers

        super(:success, headers, body)
      end

      def json_body
        json = {
          total_number_of_results: @solr_response['response']['numFound'],
          page: @parameters[:page],
          per_page: @parameters[:per_page],
          params: {},
          records: []
        }

        [:q, :sort, :order, :search_type].each do |key|
          json[:params][key] = @parameters[key]
        end

        # add filters
        json[:params][:filters] = @parameters.select{ |k, _| VALID_FILTERS.include?(k) }

        # add records
        json[:records] = semantic_documents

        json
      end

      def rss_body
        xml = Builder::XmlMarkup.new(indent: 2)
        xml.instruct! :xml, version: "1.0"
        xml.rss(version: '2.0', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1', 'xmlns:vivo' => 'http://vivoweb.org/ontology/core') {
          xml.channel {
            xml.title("Academic Commons Search Results")
            # xml.link(search_action_url(params))
            xml.description("Academic Commons Search Results")
            xml.language('en-us')

            semantic_documents.each do |doc|
              xml.item do
                xml.title doc[:title] if doc.key?(:title)
                xml.link doc[:persistent_url]

                xml.tag!('dc:creator', doc[:author].join('; ')) if doc.key?(:author)

                xml.guid doc[:identifier]                  if doc.key?(:identifier)
                xml.pubDate doc[:created_at] #.rfc822
                xml.tag!('dc:date', doc[:date])           if doc.key?(:date)
                xml.description doc[:description]         if doc.key?(:description)

                xml.tag!('dc:subject', doc[:subject].join(', '))           if doc.key?(:subject)
                xml.tag!('dc:type', doc[:content_type].join(', ')) if doc.key?(:content_type)
                xml.tag!('vivo:Department', doc[:department].join(', '))    if doc.key?(:departments)
              end
            end
          }
        }
      end

      private

        def semantic_documents
          @solr_response['response']['docs'].map { |d| SolrDocument.new(d).to_ac_api }
        end
    end
  end
end
