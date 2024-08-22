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
    deposits_enabled = SiteOption.find_by(name: 'deposits_enabled')[:value]
    if deposits_enabled
      @deposit ||= Deposit.new(
        creators: [
          { first_name: current_user.first_name || nil, last_name: current_user.last_name || nil, uni: current_user.uid }
        ]
      )
    else
      redirect_to root_path
    end
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
      SwordDepositJob.perform_later(@deposit)
      render template: 'uploads/successful_upload'
    else
      @deposit.files.attachments.each(&:destroy) # Remove attachment until we can persist them across requests.
      flash.now[:error] = @deposit.errors.full_messages.to_sentence
      Rails.logger.error @deposit.errors.inspect
      render :new, status: :bad_request
    end
  end

  private

  def upload_params
    params.require(:deposit)
          .permit(:title, :abstract, :year, :doi, :license, :rights, :notes, :degree_program, :academic_advisor, :current_student,
                  :thesis_or_dissertation, :degree_earned, :embargo_date, :previously_published, :article_version, :keywords,
                  :current_student, files: [], creators: %i[first_name last_name uni])
  end

  def send_student_reminder_email
    return unless ActiveRecord::Type::Boolean.new.cast(params[:deposit][:current_student])

    begin
      UserMailer.reminder_to_request_departmental_approval(current_user.full_name, current_user.email_preference.email).deliver
    rescue Net::SMTPFatalError, Net::SMTPSyntaxError, IOError, Net::SMTPAuthenticationError,
           Net::SMTPServerBusy, Net::SMTPUnknownError => e

      Rails.logger.warn "Error sending new student reminder email to #{current_user.full_name}. ERROR: #{e.message}"
    end
  end
end
