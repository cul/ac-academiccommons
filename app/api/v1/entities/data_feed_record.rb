module V1
  module Entities
    class DataFeedRecord < FullRecord
      # Additional fields to FullRecord exposed only by the datafeed endpoint
      expose(:partner_journal_title) { |r| r.library_partner }
    end
  end
end
