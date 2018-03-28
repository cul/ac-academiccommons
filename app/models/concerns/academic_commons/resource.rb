module AcademicCommons::Resource
  extend ActiveSupport::Concern

  CUL_MEMBER_OF = RDF::URI('http://purl.oclc.org/NET/CUL/memberOf')
  CUL_METADATA_FOR = RDF::URI('http://purl.oclc.org/NET/CUL/metadataFor')

  MAX_LIST_MEMBERS_PER_REQUEST = 500

  module ClassMethods
    def pid_namespace
      'ldpd'
    end
  end

  def belongs_to
    relationships(CUL_MEMBER_OF).map { |obj| obj.to_s.split('/')[-1] }
  end

  def repository_inbound(predicate, pids_only=false)
    begin
      i = 1
      size = repository_inbound_count(predicate)
      items = []
      while (i <= size)
        riquery = riquery_for_inbound(predicate, limit: MAX_LIST_MEMBERS_PER_REQUEST, offset: i - 1)
        options = {lang: 'itql', format: 'sparql', flush: true}
        rubydora = ActiveFedora::Base.connection_for_pid(pid)
        result = rubydora.risearch(riquery, options)

        Nokogiri::XML(result).css('sparql>results>result>member').each do |result_node|
          items << result_node.attributes['uri'].value.split('/').last
        end
        i = i + MAX_LIST_MEMBERS_PER_REQUEST
      end
      return pids_only ? items : items.lazy.map { |pid| ActiveFedora::Base.find(pid) }
    rescue Exception => e

      Rails.logger.info "======= Resource.repository_inbound(#{predicate}, #{pids_only}) error: #{e.message}"

      logger.error e.message
      []
    end
  end

  def repository_inbound_count(predicate)
    begin
      riquery = riquery_for_inbound(predicate)
      options = {lang: 'itql', format: 'count', limit: '', flush: true }
      rubydora = ActiveFedora::Base.connection_for_pid(pid)
      result = rubydora.risearch(riquery, options)
      result.body.to_i
    rescue Exception => e
      logger.error e.message
      return -1
    end
  end

  # Helper to query for members with offset. Adds ability to pagination through results.
  def riquery_for_inbound(predicate, options = {})
    limit = options.delete(:limit) || nil
    offset = options.delete(:offset) || nil

    query = ["select $member from <#ri> where $member <#{predicate}> <fedora:#{pid}>"]
    query << 'order by $member' if limit || offset
    query << "limit #{limit}" if limit
    query << "offset #{offset}" if offset
    query.join(' ')
  end
end
