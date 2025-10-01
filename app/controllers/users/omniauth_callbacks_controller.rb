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

    # TODO : in cul_omniauth, this just called a find_user method---replicate that code here?

    # oa_data = request.env.fetch(OMNIAUTH_REQUEST_KEY)
    # current_user ||= User.find_for_cas(oa_data)
    # affils ["#{oa_data['uid']}:users.cul.columbia.edu"]
    # affils << 'staff:cul.columbia.edu' if @current_user.respond_to?(:cul_staff?) && @current_user.cul_staff?
    # affils += (oa_data.fetch('extra', {})['affiliations'] || [])
    # affiliations(@current_user, affils)
    # session['devise.roles'] = affils

    current_user = User.find_by(:uid, user_id)
    if current_user && current_user.persisted?
      message = I18n.t 'devise.omniauth_callbacks.failure', kind: 'CAS'
      if message.blank?
        flash.delete[:notice]
      else
        flash[:notice] = message
      end
      sign_in_and_redirect current_user, event: :authentication
    else
      reason = current_user ? 'no persisted user for id' : 'no uid in token'
      Rails.logger.warn "#{reason} #{oa_data.inspect}"
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.failure', kind: 'CAS', reason: reason
      session['devise.cas_data'] = oa_data
      redirect_to root_url
    end

    # TODO : sign_in_and_redirect user, event: :authentication
    # I believe this callback shoudl recieve the request.env['omniauth.auth'] data, and that
    # devise manages the session for us.

    # Custom auth logic for your app goes here.
    # The code below is provided as an example.  If you want to use Omniauth::Cul::PermissionFileValidator,
    # to validate see the later "Omniauth::Cul::PermissionFileValidator" section of this README.
    #
    # if Omniauth::Cul::PermissionFileValidator.permitted?(user_id, affils)
    #   user = User.find_by(uid: user_id) || User.create!(
    #       uid: user_id,
    #       email: "#{user_id}@columbia.edu",
    #       password: Devise.friendly_token[0, 20] # Assign random string password, since the omniauth user doesn't need to know the unused local account password
    #   )
    #   sign_in_and_redirect user, event: :authentication # this will throw if @user is not activated
    # else
    #   flash[:error] = 'Login attempt failed'
    #   redirect_to root_path
    # end
  end
end
