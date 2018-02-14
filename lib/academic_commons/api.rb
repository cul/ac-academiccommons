module AcademicCommons::API
  def self.search(parameters)
    AcademicCommons::API::Search.new(parameters).response
  end
end
