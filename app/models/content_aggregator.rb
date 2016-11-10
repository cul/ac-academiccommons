class ContentAggregator < ActiveFedora::Base
  include AcademicCommons::Indexable
  include AcademicCommons::Aggregator

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

  def descMetadata_datastream
    if datastreams.keys.include?('descMetadata')
      return datastreams['descMetadata']
    else
      descPids = repository_inbound(AcademicCommons::Resource::CUL_METADATA_FOR, true)
      return nil if descPids.blank?
      return ActiveFedora::Base.find(descPids[0]).datastreams['CONTENT']
    end
  end

  def descMetadata_content
    content_ds = descMetadata_datastream
    return content_ds ? content_ds.content : nil
  end
end
