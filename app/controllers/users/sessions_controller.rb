# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  def omniauth_provider_key
    Rails.env.development? ? 'developer' : 'saml' # TODO: use cas?
  end

  # GET /resource/sign_in
  def new
    if Rails.env.development?
      redirect_to user_developer_omniauth_authorize_path
    else
      redirect_to user_cas_omniauth_authorize_path
    end
  end
end
