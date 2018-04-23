class ErrorsController < ApplicationController
  include Gaffe::Errors

  # Make sure anonymous users can see the page
  skip_before_action :require_admin!, raise: false

  def internal_server_error; end
end
