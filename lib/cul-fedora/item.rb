require "open3"
begin
  require "active_support/core_ext/array/extract_options"
rescue
  require "activesupport"
end

require 'academic_commons/indexable'
module Cul
  module Fedora
    class Item

      attr_reader :server, :pid
      include Open3
      include AcademicCommons::Indexable

      URI_TO_PID = 'info:fedora/'
      MAX_LIST_MEMBERS_PER_REQUEST = 500

      def <=>(other)
        pid <=> other.pid
      end

      def pid_escaped
        pid.gsub(/:/,'\\:')
      end

      def initialize(*args)
        options = args.extract_options!
        @server = options[:server] || Server.new(options[:server_config])
        @logger = options[:logger]
        @pid = options[:pid] || options[:uri] || raise(ArgumentError, "requires uri or pid")
        @pid = @pid.to_s.sub(URI_TO_PID, "")
      end

      def logger
        @logger ||= Logger.new
      end

      def ==(other)
        self.server == other.server
        self.pid == other.pid
      end

      def exists?
        begin
          request
          return true
        rescue Exception => e # we should really do some better checking of error type etc here
    logger.error "no object was found for fedora pid  #{pid}"
          logger.error e.message
          return false
        end
      end

      def request(options = {})
        @server.request(options.merge(:pid => @pid))
      end

      def request_path(options = {})
        @server.request_path(options.merge(:pid => @pid))
      end

      def getIndex(profile = "raw")
        Nokogiri::XML(request(:request => "getIndex", :sdef => "ldpd:sdef.Core", :profile => profile))
      end

      def datastream(name)
        request(:request => name.to_s.upcase)
      end

      def listMembers(pids_only=false)
        begin
          i = 1
          size = getSize
          items = []
          while (i <= size)
            riquery = riquery_for_members(limit: MAX_LIST_MEMBERS_PER_REQUEST, offset: i - 1)
            result = Nokogiri::XML(@server.request(:method => "", :request => "risearch", :format => "sparql", :lang => "itql", :query => riquery))

            result.css("sparql>results>result>member").collect do |result_node|
              pids = result_node.attributes["uri"].value.split('/').last
              items << pids_only ? pid : @server.item(pid)
            end
            i = i + MAX_LIST_MEMBERS_PER_REQUEST
          end
          return items
        rescue Exception => e

          Rails.logger.info "======= tika listMembers error: " + e.message

          logger.error e.message
          []
        end
      end

      # Helper to query for members with offset. Adds ability to pagination through results.
      def riquery_for_members(options = {})
        limit = options.delete(:limit) || nil
        offset = options.delete(:offset) || nil

        query = ["select $member from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:#{pid}>"]
        query << "order by $member" if limit || offset
        query << "limit #{limit}" if limit
        query << "offset #{offset}" if offset
        query.join(" ")
      end

      def getSize()
        begin
            @server.request(:method => "", :request => "risearch", :format => "count", :lang => "itql", :query => riquery_for_members, :limit => '').to_i
        rescue Exception => e
          logger.error e.message
          return -1
        end
      end

      def describedBy
        begin
          riquery = "select $description from <#ri> where $description <http://purl.oclc.org/NET/CUL/metadataFor> <fedora:#{pid}>"
          result = @server.request(:method => "", :request => "risearch", :format => "sparql", :lang => "itql", :query => riquery, :limit => 1)
          Nokogiri::XML(result).css("sparql>results>result>description").collect do |metadata|
            @server.item(metadata.attributes["uri"].value)
          end
        rescue Exception => e
          logger.error e.message
          []
        end
      end

      def belongsTo
        begin
          result = Nokogiri::XML(datastream("RELS-EXT"))
          result.xpath("/rdf:RDF/rdf:Description/*[local-name()='memberOf']").collect do |member|
            @server.item(member.attributes["resource"].value)
          end
        rescue Exception => e
          logger.error e.message
          []
        end
      end

      def get_resource_pid(aggregator_pid)
        riquery = "select $member from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:#{aggregator_pid}>"
        response = @server.request(:method => "", :request => "risearch", :format => "sparql", :lang => "itql", :query => riquery, limit: 1)
        #aggregator_members_url = Rails.application.config.fedora['open_url'] + '/objects/' + aggregator_pid + '/methods/ldpd:sdef.Aggregator/listMembers?format=sparql&max=1&start=0'
        #response = Net::HTTP.get_response(URI(aggregator_members_url))
        contentXML = Nokogiri::XML(response.to_s)
        member_node = contentXML.css("member")
        resourse_pid = member_node.first['uri']
        return resourse_pid.sub('info:fedora/', '')
      end

      def check_if_resouce_is_available(resourse_pid)
        fedora_url = URI(@server.riurl)

        response = Net::HTTP.start(fedora_url.hostname, fedora_url.port, :use_ssl => fedora_url.scheme == 'https') do |http|
          http.head("/objects/#{resourse_pid}")
        end
        return response.code == '200'
      end

      def make_resource_active(resource_pid)
        logger.error "WARNING: Call made to make_resource_active() by #{pid}"

        #change_resourse_state_url = Rails.application.config.fedora['pid_state_changer_url'] + '?pid=' + resource_pid + '&repository_id=2&state=A'
        #Net::HTTP.get_response(URI(change_resourse_state_url))
      end

      def descMetadata_content
        meta = describedBy.first
        meta ? meta.datastream("CONTENT") : datastream("descMetadata")
      end

      def index_for_ac2(options = {})
        #do_fulltext = options[:fulltext] || false
        do_fulltext = false

        do_metadata = options[:metadata] || true

        status = :success
        error_message = ""

        results = {}

        begin
          index_descMetadata(results) if do_metadata
        rescue Exception => e
          status = :error
          error_message += e.message
          Rails.logger.info "=== indexing error: " + e.message
        end

        status = :invalid_format  if results.empty?

        return {:status => status, :error_message => error_message, :results => results}

      end

      def to_s
        @pid
      end
    end
  end
end
