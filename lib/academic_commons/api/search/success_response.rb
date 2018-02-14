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
        json[:records] = documents.map do |doc|
          fields = [:id, :title, :author, :abstract, :department, :date, :subject, :genre, :language, :persistent_url, :created_at]
          semantics_hash = doc.to_semantic_values
          fields.map { |f| [f, semantics_hash[f]] }.to_h
        end
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

            documents.each do |doc|
              semantic = doc.to_semantic_values
              xml.item do
                xml.title semantic[:title].first if semantic.key?(:title)
                xml.link semantic[:persistent_url]

                xml.tag!('dc:creator', semantic[:author].join('; ')) if semantic.key?(:author)

                xml.guid semantic[:identifier]                       if semantic.key?(:identifier)
                xml.pubDate doc.timestamp.rfc822
                xml.tag!('dc:date', semantic[:date].first)           if semantic.key?(:date)
                xml.description semantic[:description].first         if semantic.key?(:description)

                xml.tag!('dc:subject', semantic[:subject].join(', '))           if semantic.key?(:subject)
                xml.tag!('dc:type', semantic[:content_type].join(', ')) if semantic.key?(:content_type)
                xml.tag!('vivo:Department', semantic[:departments].join(', '))    if semantic.key?(:departments)
              end
            end
          }
        }
      end

      private

        def documents
          @solr_response['response']['docs'].map { |d| SolrDocument.new(d) }
        end
    end
  end
end
