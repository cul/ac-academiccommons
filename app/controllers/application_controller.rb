class ApplicationController < ActionController::Base
  
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery
  
  helper_method :user_session, :current_user_session, :current_user
  
  def login
    # redirect_to :controller => 'catalog' :action => 'index'
  end
  
  def logout
    # redirect_to :controller => 'catalog', :action => 'index'  
  end
  
  def user_session
    current_user_session
  end
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end
  
end
