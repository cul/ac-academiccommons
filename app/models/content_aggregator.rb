class ContentAggregator < ActiveFedora::Base
  include AcademicCommons::Aggregator

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
