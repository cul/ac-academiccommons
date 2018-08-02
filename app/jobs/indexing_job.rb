class IndexingJob < ApplicationJob
  # Indexes the pid provided
  def perform(pid)
    # Using direct solr query to index an item/asset without soft commiting.
    # autoCommit will take care of presisting the new document. This change
    # is required when indexing multiple items in parallel.
    obj = ActiveFedora::Base.find(pid)
    solr_doc = obj.to_solr
    ActiveFedora::SolrService.add(solr_doc)

    Rails.cache.delete('repository_statistics') # Invalidating stats on homepage.
  end
end
