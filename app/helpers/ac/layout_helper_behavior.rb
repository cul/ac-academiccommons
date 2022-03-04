# frozen_string_literal: true
# Methods added to this helper will be available to all templates in the hosting
# application
# A module for useful methods used in layout configuration
module Ac::LayoutHelperBehavior
  ## !Override
  # Classes used for sizing the main content of a Blacklight page
  # @return [String]
  def main_content_classes
    'col-md-8 col-sm-7'
  end

  ## !Override
  # Classes used for sizing the sidebar content of a Blacklight page
  # @return [String]
  def sidebar_classes
    'col-md-4 col-sm-5'
  end
end
