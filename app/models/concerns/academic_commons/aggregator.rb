module AcademicCommons::Aggregator
  extend ActiveSupport::Concern

  included do
    include AcademicCommons::Resource
  end

  URI_TO_PID = 'info:fedora/'

  def pid_escaped
    "\"#{self.pid}\""
  end

  def to_solr(solr_doc={}, options={})
    solr_doc = super
    return index_descMetadata(solr_doc)
  end

  def list_members(pids_only=false)
    repository_inbound(AcademicCommons::Resource::CUL_MEMBER_OF, pids_only)
  end

  # Helper to query for members with offset. Adds ability to pagination through results.
  def riquery_for_members(options = {})
    riquery_for_inbound(AcademicCommons::Resource::CUL_MEMBER_OF, options)
  end

  def repository_size
    repository_inbound_count(AcademicCommons::Resource::CUL_MEMBER_OF)
  end
end
