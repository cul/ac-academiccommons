class AgreementsController < ApplicationController
  load_and_authorize_resource

  def show
    redirect_to(action: :new) unless current_user.signed_latest_agreement?
  end

  def new
    redirect_to(action: :show) if current_user.signed_latest_agreement?

    @agreement = Agreement.new
  end

  # Endpoint for logged in user to accept author agreement.
  def create
    if params[:agreement][:accepted_agreement]
      agreement = Agreement.new(agreement_params)
      agreement.user = current_user

      NotificationMailer.new_agreement(
        agreement_params[:name],
        agreement_params[:email],
        agreement_params[:agreement_version]
      ).deliver

      if agreement.save
        flash[:notice] = 'Author Agreement Accepted.'
        redirect_to uploads_path
      else
        flash[:error] = 'There was an error submitting your agreement form, please make sure ALL fields are filled.'
        redirect_to action: :new
      end
    else
      flash[:error] = 'You must accept the participation agreement.'
      redirect_to action: :new
    end
  end

  private

  def agreement_params
    params.require(:agreement).permit(:uni, :agreement_version, :name, :email)
  end
end
