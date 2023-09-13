# frozen_string_literal: true

module AcademicCommons
  module Exceptions
    class AcademicCommonsError < StandardError; end

    class DescriptiveMetadataValidationError < AcademicCommonsError; end
  end
end
