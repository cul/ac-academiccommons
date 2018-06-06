class UploadsController < ApplicationController
  # TODO: require authentication and add to abilities

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
    deposit = Deposit.new(upload_params)
    deposit.files.attach(params[:deposit][:files])
    # TODO: make deposit belong_to logged_in user

    # TODO: validate that required fields are inputted
    # required fields: 1 creator, right statement, title, file, abstract and year
    if deposit.save
      render template: 'uploads/successful_upload'
    else
      flash[:error] = 'Error saving deposit, please make sure all required fields are entered.'
      Rails.logger.debug deposit.errors.inspect
      redirect_to action: :new
    end
  end

  private

  def upload_params
    params.require(:deposit)
          .permit(:title, :creators, :abstract, :year, :doi, :license, :rights_statement, :notes)
  end
end
