class UploadsController < ApplicationController
  load_and_authorize_resource class: Deposit, except: :index

  # GET /upload
  # Show upload landing page page if user is not logged in. If user is logged
  # in redirect to /upload/new
  def index
    redirect_to action: :new unless current_user.nil?
  end

  # GET /upload/new
  # Show upload form, if user is logged in.
  def new
    @deposit ||= Deposit.new
  end

  # POST /upload
  def create
    @deposit = Deposit.new(upload_params)
    @deposit.files.attach(params[:deposit][:files])
    @deposit.user = current_user
    @deposit.authenticated = true
    # TODO: save user name and uni in deposit object

    # TODO: validate that required fields are inputted
    # required fields: 1 creator, right statement, title, file, abstract and year
    if @deposit.save
      render template: 'uploads/successful_upload'
    else
      flash[:error] = 'Error saving deposit, please make sure all required fields are entered.'
      Rails.logger.debug @deposit.errors.inspect
      render :new
    end
  end

  private

  def upload_params
    params.require(:deposit)
          .permit(:title, :creators, :abstract, :year, :doi, :license, :rights_statement, :notes)
  end
end
