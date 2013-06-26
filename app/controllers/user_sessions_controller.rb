class UserSessionsController < ApplicationController
  
  require File.expand_path(File.dirname(__FILE__) + '../../../lib/authlogic_wind/session.rb')
  
  unloadable
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def index
    if(params[:id] && params[:id] == "create")
      create
    end
  end

  def new
    user_session.destroy if user_session
    @user_session = UserSession.new
    params[:login_with_wind] = true if UserSession.login_only_with_wind
    session[:return_to] ||= params[:return_to] || root_url
    @user_session.save 
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|  
      if result  
        session[:return_to] = nil if session[:return_to].to_s.include?("logout")
        redirect_back_or_default(root_url, "new_session=true")  
      else  
        flash[:error] = "Unsuccessfully logged in."
        redirect_to session[:return_to] || root_url
      end  
    end
    
  end
  
  def destroy
    user_session.destroy
    redirect_to root_url
  end
  
end
