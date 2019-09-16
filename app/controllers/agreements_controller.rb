class AgreementsController < ApplicationController
  load_and_authorize_resource       unless: :token?
  before_action :verify_token,      if:     :token?

  helper_method :token?, :token

  def show
    redirect_to(action: :new) unless current_user.signed_latest_agreement?
  end

  def new
    Rails.logger.debug params.inspect
    redirect_to(action: :show) if !token? && current_user.signed_latest_agreement?

    @agreement ||= Agreement.new(agreement_params)
    @agreement.uni = current_user.uid unless token?
  end

  # Endpoint for logged in user to accept author agreement.
  def create
    @agreement = Agreement.new(agreement_params)
    @agreement.user = current_user     unless token?
    @agreement.uni  = current_user.uid unless token?

    if ActiveRecord::Type::Boolean.new.cast(params[:agreement][:accepted_agreement])
      if @agreement.save
        flash[:notice] = 'Author Agreement Accepted.'

        AdministrativeMailer.new_agreement(
          agreement_params[:name],
          agreement_params[:email],
          agreement_params[:agreement_version]
        ).deliver

        redirect_to token? ? root_path : uploads_path
      else
        flash[:error] = @agreement.errors.full_messages.to_sentence
        render :new
      end
    else
      flash[:error] = 'You must accept the participation agreement.'
      render :new
    end
  end

  private

    def token
      params.dig(:agreement, :token)
    end

    def token?
      token.present?
    end

    def verify_token
      creds = Rails.application.message_verifier(:agreement).verify(token)
      raise CanCanCan::AccessDenied if creds.nil? || creds.is_a?(ActiveSupport::MessageVerifier::InvalidSignature) || creds[2] != Agreement::LATEST_AGREEMENT_VERSION
      params[:agreement] = (params[:agreement] || {}).merge(email: creds[0], uni: creds[1])
    end

    def agreement_params
      params.require(:agreement).permit(:uni, :agreement_version, :name, :email)
    end
end
