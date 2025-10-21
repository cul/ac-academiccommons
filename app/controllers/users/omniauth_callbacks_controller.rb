# frozen_string_literal: true

require 'omniauth/cul'

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  OMNIAUTH_REQUEST_KEY = 'omniauth.auth'

  # Adding the line below so that if the auth endpoint POSTs to our cas endpoint, it won't
  # be rejected by authenticity token verification.
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :cas

  def app_cas_callback_endpoint
    "#{request.base_url}/users/auth/cas/callback"
  end

  # In local development, use devise's controller. In deployed env, use CAS server
  def passthru
    if Rails.env.development?
      super
    else
      redirect_to Omniauth::Cul::Cas3.passthru_redirect_url(app_cas_callback_endpoint), allow_other_host: true
    end
  end

  def developer
    current_user ||= User.find_or_create_by(
      uid: request.env['omniauth.auth'][:uid], provider: :developer
    )

    sign_in_and_redirect current_user, event: :authentication
  end

  def cas
    user_id, _affils = Omniauth::Cul::Cas3.validation_callback(request.params['ticket'], app_cas_callback_endpoint)

    user = User.find_by(uid: user_id) || User.create!(
      uid: user_id,
      email: "#{user_id}@columbia.edu"
    )
    sign_in_and_redirect user, event: :authentication
  end
end
