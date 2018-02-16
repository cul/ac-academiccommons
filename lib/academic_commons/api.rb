module AcademicCommons::API
  def self.search(parameters)
    AcademicCommons::API::Search.new(parameters).response
  end

  def self.feed(*parameters)
    AcademicCommons::API::Feed.new(*parameters).response
  end
end
