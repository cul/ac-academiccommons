class Resource < ActiveFedora::Base
  include AcademicCommons::Resource
  def to_solr(solr_doc={}, options={})
    solr_doc = super
    solr_doc['pid'] ||= self.pid
    content = downloadable_content
    if content
      solr_doc['downloadable_content_type_ssi'] = content.mimeType
      solr_doc['downloadable_content_dsid_ssi'] = content.dsid
      solr_doc['downloadable_content_label_ss'] = content.label.blank? ? this.label : content.label
    end
    solr_doc
  end
  def downloadable_content
    return datastreams['CONTENT'] if (datastreams.has_key?('CONTENT'))
    return datastreams['content'] if (datastreams.has_key?('content'))
    return nil
  end
end