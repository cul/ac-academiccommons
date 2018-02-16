module AcademicCommons::API
  class Feed
    attr_reader :response

    def initialize(key, authorized)
      @response = if !authorized
                    ErrorResponse.new(:json, ["Not Authorized"], :not_authorized)
                  elsif feed = Feed.find(key)
                    Search.new(feed.parameters)
                  else
                    ErrorResponse.new(:json, ["Feed key invalid"], :bad_request)
                  end
    end
  end
end
