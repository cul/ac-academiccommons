class ApplicationController < ActionController::Base
  
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery

  layout "application"
  
  before_filter :check_new_session
  
  helper :all # include all helpers, all the time
  helper_method :user_session, :current_user_session, :current_user, :fedora_config, :solr_config, :relative_root # share some methods w/ views via helpers
  
  def fedora_config
    @fedora_config ||= Rails.configuration.fedora
  end
  
  def solr_config
    @solr_config ||= Rails.configuration.solr
  end
  
  def fedora_server
    @fedora_server ||= Cul::Fedora::Server.new(fedora_config)
  end

  def solr_server
    @solr_server ||= Cul::Fedora::Solr.new(solr_config)
  end

  def relative_root
    Rails.configuration.relative_root || ""
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default, additional_params)
    to_url = session[:return_to] || default
    if(additional_params)
      if(to_url.include?('?'))
        to_url = to_url + "&" + additional_params
      else
        to_url = to_url + "?" + additional_params
      end
    end
    redirect_to(to_url)
    session[:return_to] = nil
  end

  def pid_exists?(pid)
    `ps -p #{pid}`.include?(pid)
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  def javascript_tag(href)
    '<script src="' + href + '" type="text/javascript"></script>'.html_safe
  end
  
  def stylesheet_tag(href, args)
    '<link href="' + href + '" rel="stylesheet" type="text/css" media="' + args[:media] + '" />'.html_safe
  end
  
  def default_html_head
    stylesheet_links << ['zooming_image', 'accordion', {:media=>'all'}]
    stylesheet_links << [ 'jquery/ui-lightness/jquery-ui-1.8.1.custom.css']
    stylesheet_links << [ 'handheld.css?v=1',{:media=>'handheld'}]
    javascript_includes << ['accordion']
  end
  
  ##########################################
  #### Application user-related methods ####
  ##########################################

  def access_denied
    render :template => 'access_denied'
  end
  
  def check_new_session
    if(params[:new_session])
      current_user.set_personal_info_via_ldap
      current_user.save
    end
  end
  
  def require_user
    unless current_user
      store_location
      redirect_to new_user_session_path
      return false
    end
  end

  def require_admin
    if current_user
      unless current_user.admin
        redirect_to access_denied_url  
      end
    else
      store_location
      redirect_to new_user_session_path
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_url
      return false
    end
  end
  
  def user_session
    return @user_session if defined?(@user_session)
    @user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = user_session && user_session.user
  end
  
end
