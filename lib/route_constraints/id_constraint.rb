# frozen_string_literal: true

module RouteConstraints
  class IdConstraint
    DOI_PATTERN = %r{\A10\.\d{4,9}(?:\.\d+)*/[[:print:]]+\z}
    PID_PATTERN = /\Aac:[a-zA-Z0-9]+\z/

    def matches?(request)
      id = request.path_parameters[:id]
      return false if id.blank?

      id.match?(DOI_PATTERN) || id.match?(PID_PATTERN)
    end
  end
end
