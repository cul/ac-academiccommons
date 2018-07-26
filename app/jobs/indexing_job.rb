class IndexingJob < ApplicationJob
  # Indexes the pid provided
  def perform(pid)
    i = ActiveFedora::Base.find(pid)
    i.update_index
  end
end
