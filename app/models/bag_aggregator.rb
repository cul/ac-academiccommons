class BagAggregator < ActiveFedora::Base
  include AcademicCommons::Indexable

  URI_TO_PID = 'info:fedora/'
  MAX_LIST_MEMBERS_PER_REQUEST = 500

  def pid_escaped
    "\"#{self.pid}\""
  end

  def to_solr(solr_doc={}, options={})
    solr_doc = super
    return index_descMetadata(solr_doc)
  end

  def list_members(pids_only=false)
    begin
      i = 1
      size = get_size
      items = []
      while (i <= size)
        riquery = riquery_for_members(limit: MAX_LIST_MEMBERS_PER_REQUEST, offset: i - 1)
        options = {lang: 'itql', format: "sparql"}
        rubydora = ActiveFedora::Base.connection_for_pid(pid)
        result = rubydora.risearch(riquery, options)

        Nokogiri::XML(result).css("sparql>results>result>member").each do |result_node|
          items << result_node.attributes["uri"].value.split('/').last
        end
        i = i + MAX_LIST_MEMBERS_PER_REQUEST
      end
      return pids_only ? items : items.lazy.map { |pid| ActiveFedora::Base.find(pid) }
    rescue Exception => e

      Rails.logger.info "======= BagAggregator.list_members error: " + e.message

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

  def get_size
    begin
      riquery = riquery_for_members()
      options = {lang: 'itql', format: "count", limit: '' }
      rubydora = ActiveFedora::Base.connection_for_pid(pid)
      result = rubydora.risearch(riquery, options)
      result.to_i
    rescue Exception => e
      logger.error e.message
      return -1
    end
  end
end