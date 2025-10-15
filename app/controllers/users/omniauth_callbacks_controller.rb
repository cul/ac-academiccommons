# frozen_string_literal: true

require 'omniauth/cul'

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  OMNIAUTH_REQUEST_KEY = 'omniauth.auth'

  before_action :enforce_post_request, only: :passthru

  # Adding the line below so that if the auth endpoint POSTs to our cas endpoint, it won't
  # be rejected by authenticity token verification.
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :cas

  def app_cas_callback_endpoint
    #  TODO : in dev do developer callback?
    "#{request.base_url}/users/auth/cas/callback"
  end

  def passthru
    redirect_to Omniauth::Cul::Cas3.passthru_redirect_url(app_cas_callback_endpoint), allow_other_host: true
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

  private

  def enforce_post_request
    unless request.post?
      puts "REJECTED #{request.method} req to #{request.path} - POST REQUIRED!"
      render plain: 'method not allowed. POST required', status: :method_not_allowed
    end
  end
end
