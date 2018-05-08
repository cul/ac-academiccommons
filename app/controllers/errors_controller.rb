class ErrorsController < ApplicationController
  include Gaffe::Errors

  # Make sure anonymous users can see the page
  skip_load_and_authorize_resource

  def internal_server_error; end
end
