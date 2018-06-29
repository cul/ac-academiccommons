class UploadsController < ApplicationController
  load_and_authorize_resource class: Deposit, except: :index

  layout 'dashboard'

  # GET /upload
  # Show upload landing page page if user is not logged in. If user is logged
  # in redirect to /upload/new
  def index
    redirect_to(action: :new) && return if current_user
    render layout: 'main'
  end

  # GET /upload/new
  # Show upload form, if user is logged in.
  def new
    @deposit ||= Deposit.new(
      creators: [
        { first_name: current_user.first_name, last_name: current_user.last_name, uni: current_user.uid }
      ]
    )
  end

  # POST /upload
  def create
    @deposit = Deposit.new(upload_params)
    @deposit.user = current_user
    @deposit.authenticated = true
    @deposit.name = current_user.full_name
    @deposit.uni =  current_user.uid

    if @deposit.save
      send_student_reminder_email
      render template: 'uploads/successful_upload'
    else
      @deposit.files.attachments.destroy_all # Remove attachment until we can presist them across requests.
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

  def send_student_reminder_email
    return unless ActiveRecord::Type::Boolean.new.cast(params[:deposit][:student])

    begin
      NotificationMailer.reminder_to_request_departmental_approval(current_user.full_name, current_user.email).deliver
    rescue Net::SMTPFatalError, Net::SMTPSyntaxError, IOError, Net::SMTPAuthenticationError,
           Net::SMTPServerBusy, Net::SMTPUnknownError => e

      Rails.logger.warn "Error sending new student reminder email to #{current_user.full_name}. ERROR: #{e.message}"
    end
  end
end
