module AcademicCommons::API
  class ErrorResponse < BaseResponse
    attr_reader :body, :status, :headers

    def initialize(format, errors, status)
      @status = status
      @body = generate_body(errors, format)
    end

    def generate_body(errors, format)
      case format
      when 'json'
        { status: status, errors: errors }
      when 'rss'
        'Error generating rss feed'
      else
        'Invalid Format'
      end
    end
  end
end
