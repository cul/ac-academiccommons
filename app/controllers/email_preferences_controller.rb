class EmailPreferencesController < ApplicationController
  before_filter :require_admin
  layout "application"

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
    @email_preference = EmailPreference.new(params[:email_preference])
    if @email_preference.save
      flash[:notice] = "Successfully created email preference."
      redirect_to @email_preference
    else
      render :action => 'new'
    end
  end
  
  def edit
    @email_preference = EmailPreference.find(params[:id])
  end
  
  def update
    @email_preference = EmailPreference.find(params[:id])
    if @email_preference.update_attributes(params[:email_preference])
      flash[:notice] = "Successfully updated email preference."
      redirect_to @email_preference
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @email_preference = EmailPreference.find(params[:id])
    @email_preference.destroy
    flash[:notice] = "Successfully destroyed email preference."
    redirect_to email_preferences_url
  end
end
