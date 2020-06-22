class ErrorsController < ApplicationController
  include Gaffe::Errors

  # Make sure anonymous users can see the page
  skip_load_and_authorize_resource

  def show
    if @exception.is_a?(Blacklight::Exceptions::RecordNotFound)
      render 'errors/record_not_found', status: @status_code
    else
      super
    end
  end

  def internal_server_error; end
end
