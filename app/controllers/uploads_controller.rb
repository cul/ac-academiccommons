class UploadsController < ApplicationController
  load_and_authorize_resource class: Deposit, except: :index

  layout 'dashboard'

  # layout 'main', only: [:index]

  # GET /upload
  # Show upload landing page page if user is not logged in. If user is logged
  # in redirect to /upload/new
  def index
    redirect_to(action: :new) and return if current_user
    render layout: 'main'
  end

  # GET /upload/new
  # Show upload form, if user is logged in.
  def new
    @deposit ||= Deposit.new
  end

  # POST /upload
  def create
    @deposit = Deposit.new(upload_params)
    @deposit.user = current_user
    @deposit.authenticated = true
    @deposit.name = current_user.full_name
    @deposit.uni =  current_user.uid

    if @deposit.save
      render template: 'uploads/successful_upload'
    else
      flash[:error] = @deposit.errors.full_messages.to_sentence
      Rails.logger.debug @deposit.errors.inspect
      render :new
    end
  end

  private

  def upload_params
    params.require(:deposit)
          .permit(:title, :abstract, :year, :doi, :license, :rights_statement, :notes, files: [], creators: %i[first_name last_name uni])
  end
end
