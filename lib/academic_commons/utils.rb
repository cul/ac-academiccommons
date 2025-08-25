module AcademicCommons
  module Utils
    def self.rsolr
      url = Rails.application.config_for(:solr)[:url]
      RSolr.connect(url: url)
    end
  end
end
