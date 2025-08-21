class ApplicationController < ActionController::Base
  include Blacklight::Controller
  include Devise::Controllers::Helpers

  protect_from_forgery

  layout 'main'

  helper :all # include all helpers, all the time
  helper_method :fedora_config # share some methods w/ views via helpers

  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil?
      respond_to do |format|
        format.json { render json: { 'error' => 'forbidden' }, status: :forbidden }
        format.html { redirect_to new_user_session_path }
        format.csv  { redirect_to new_user_session_path }
      end
    else
      raise exception
    end
  end

  def fedora_config
    @fedora_config ||= Rails.application.config_for(:fedora)
  end

  def is_bot?(user_agent)
    user_agent.nil? || VoightKampff.bot?(user_agent)
  end

  def new_session_path(scope)
    new_user_session_path
  end

  private

  # Redirect to last page a user visited before log in.
  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || stored_location_for(resource) || root_path
  end
end
