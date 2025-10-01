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

  def passthru
    session['user_return_to'] = request.params['origin'] || request.referer || root_url
    redirect_to Omniauth::Cul::Cas3.passthru_redirect_url(app_cas_callback_endpoint), allow_other_host: true
  end

  def developer
    current_user ||= User.find_or_create_by(
      uid: request.env['omniauth.auth'][:uid], provider: :developer
    )

    sign_in_and_redirect current_user, event: :authentication
  end

  def cas
    user_id, affils = Omniauth::Cul::Cas3.validation_callback(request.params['ticket'], app_cas_callback_endpoint)
    Rails.logger.debug 'inside cas callback method'
    Rails.logger.debug "user_id: #{user_id} and affils: #{affils}"
    Rails.logger.debug 'request env omniauth.auth is :'
    Rails.logger.debug request.env[OMNIAUTH_REQUEST_KEY].inspect
    Rails.logger.debug 'request.env[omniauth_origin]:'
    Rails.logger.debug request.env[omniauth_origin].inspect

    user = User.find_by(uid: user_id) || User.create!(
            uid: user_id,
            email: "#{user_id}@columbia.edu",
            password: Devise.friendly_token[0, 20]
          )
    # TODO : almost working; needs to redirect back to last visited page, not root URL
    sign_in_and_redirect user, event: :authentication
  end
end
