class EmailPreferencesController < ApplicationController
  before_action :require_admin!
  layout 'application'

  def index
    @email_preferences = EmailPreference.all
  end

  def show
    @email_preference = EmailPreference.find(params[:id])
  end

  def new
    @email_preference = EmailPreference.new
  end

  def create
    @email_preference = EmailPreference.new(email_preference_params)
    if @email_preference.save
      flash[:success] = 'Successfully created email preference.'
      redirect_to @email_preference
    else
      render action: :new
    end
  end

  def edit
    @email_preference = EmailPreference.find(params[:id])
  end

  def update
    @email_preference = EmailPreference.find(params[:id])
    if @email_preference.update_attributes(email_preference_params)
      flash[:success] = 'Successfully updated email preference.'
      redirect_to @email_preference
    else
      render action: :edit
    end
  end

  def destroy
    @email_preference = EmailPreference.find(params[:id])
    @email_preference.destroy
    flash[:success] = 'Successfully destroyed email preference.'
    redirect_to email_preferences_url
  end

  private
    def email_preference_params
      params.require(:email_preference).permit(:author, :monthly_opt_out, :email)
    end
end
