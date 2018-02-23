module AcademicCommons
  module API
    autoload :ErrorResponse, 'academic_commons/api/error_response'
    autoload :Fields,        'academic_commons/api/fields'

    def self.search(parameters)
      AcademicCommons::API::Search::Request.new(parameters).response
    end

    def self.feed(*parameters)
      AcademicCommons::API::Feed::Request.new(*parameters).response
    end
  end
end
