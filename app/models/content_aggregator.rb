class ContentAggregator < ActiveFedora::Base
  include AcademicCommons::Indexable

  CUL_MEMBER_OF = RDF::URI("http://purl.oclc.org/NET/CUL/memberOf")

  def pid_escaped
    "\"#{self.pid}\""
  end

  def to_solr(solr_doc={}, options={})
    solr_doc = super
    solr_doc = index_descMetadata(solr_doc)
    solr_doc
  end

  def index_for_ac2(options={})
    solr_doc = nil
    error_message = ''
    begin
      solr_doc = to_solr({},options)
      status = solr_doc.blank? ? :invalid_format : :success
    rescue Exception => e
      status = :error
      error_message += e.message
      Rails.logger.info "=== indexing error: " + e.message
      Rails.logger.debug e
    end

    result = { results: solr_doc, status: status, error_message: error_message }
    result
  end

  def descMetadata_content
  	if datastreams.keys.include?('descMetadata')
      return datastreams['descMetadata'].content
    else
      begin
        riquery = "select $description from <#ri> where $description <http://purl.oclc.org/NET/CUL/metadataFor> <fedora:#{pid}>"
        options = {lang: 'itql', format: "sparql", limit: 1 }
        rubydora = ActiveFedora::Base.connection_for_pid(pid)
        result = rubydora.risearch(riquery, options)
        descPids = Nokogiri::XML(result).css("sparql>results>result>description").collect do |metadata|
          metadata.attributes["uri"].value.split('/').last
        end
        if !descPids.empty?
          return ActiveFedora::Base.find(descPids[0]).datastreams['CONTENT'].content
        end
      rescue Exception => e
        logger.error e.message
        return nil
      end
    end
  end

  def belongs_to
    relationships(CUL_MEMBER_OF).map { |obj| obj.to_s.split('/')[-1] }
  end
end