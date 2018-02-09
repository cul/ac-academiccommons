class ApplicationController < ActionController::Base
  include Blacklight::Controller
  include Devise::Controllers::Helpers

  protect_from_forgery
  
  layout 'blacklight'


  helper :all # include all helpers, all the time
  helper_method :fedora_config # share some methods w/ views via helpers

  def fedora_config
    @fedora_config ||= Rails.configuration.fedora
  end

  # Authenticate a user using Devise and then check that the user is an
  # administrator. If user not an admin, user gets redirected to access_denied_url
  # denied page.
  def require_admin!
    authenticate_user!

    if !user_signed_in? || !current_user.admin
      raise AcademicCommons::Exceptions::NotAuthorized
    end
  end

  def is_bot?(user_agent)
    user_agent.nil? || VoightKampff.bot?(user_agent)
  end

  def new_session_path(scope)
    new_user_session_path
  end
end
