class ErrorsController < ApplicationController
  include Gaffe::Errors

  # Make sure anonymous users can see the page
  # skip_before_action :require_admin!
end
