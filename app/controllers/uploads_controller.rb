class UploadsController < ApplicationController
  # GET /upload
  # Show deposit landing page page if user is not logged in. If user is logged
  # in redirect to /upload/new
  def index
    redirect_to action: :new unless current_user.nil?
  end

  # GET /upload/new
  # Show deposit form, if user is logged in.
  def new
    @deposit = Deposit.new
  end
end
