class IndexingJob < ApplicationJob
  # Indexes the pid provided
  def perform(pid)
    i = ActiveFedora::Base.find(pid)
    i.update_index

    Rails.cache.delete('repository_statistics') # Invalidating stats on homepage.
  end
end
