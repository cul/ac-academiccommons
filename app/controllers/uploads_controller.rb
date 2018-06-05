class UploadsController < ApplicationController
  # GET /upload
  # Show upload landing page page if user is not logged in. If user is logged
  # in redirect to /upload/new
  def index
    redirect_to action: :new unless current_user.nil?
  end

  # GET /upload/new
  # Show upload form, if user is logged in.
  def new
    @deposit = Deposit.new
  end

  # POST /upload
  def create
    deposit = Deposit.create! upload_params
    deposit.files.attach(params[:deposit][:files])
    # if creation is sucessful render
    render template: 'uploads/successful_upload'
  end

  private

  def upload_params
    params.require(:deposit).permit(:content)
  end
end
