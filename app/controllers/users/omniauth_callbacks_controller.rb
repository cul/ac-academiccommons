# frozen_string_literal: true

require 'omniauth/cul'

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  # The CAS login redirect to the columbia_cas callback endpoint AND the developer form submission to the
  # developer_uid callback do not send authenticity tokens, so we'll skip token verification for these actions.
  skip_before_action :verify_authenticity_token, only: [:columbia_cas, :developer_uid]

  # POST /users/auth/developer_uid/callback
  def developer_uid
    return unless Rails.env.development? # Only allow this action to run in the development environment

    uid = params[:uid]
    user = User.find_by(uid: uid)

    unless user
      flash[:alert] = "Login attempt failed.  User #{uid} does not have an account."
      redirect_to root_path
      return
    end

    flash[:success] = 'You have succesfully logged in.'
    sign_in_and_redirect user, event: :authentication # this will throw if user is not activated
  end

  # POST /users/auth/columbia_cas/callback
  def columbia_cas # rubocop:disable Metrics/AbcSize
    callback_url = user_columbia_cas_omniauth_callback_url # The columbia_cas callback route in this application
    uid, _affils = Omniauth::Cul::ColumbiaCas.validation_callback(request.params['ticket'], callback_url)

    user = User.find_by(uid: uid) || User.create(uid: uid, email: "#{uid}@columbia.edu")
    flash[:success] = 'You have succesfully logged in.'
    sign_in_and_redirect user, event: :authentication
  rescue Omniauth::Cul::Exceptions::Error => e
    # If an unexpected CAS ticket validation occurs, log the error message and ask the user to try
    # logging in again.  Do not display the exception object's original message to the user because it may
    # contain information that only a developer should see.
    error_message = 'CAS login validation failed. Please try again.'
    Rails.logger.debug(error_message + "  #{e.class.name}: #{e.message}")
    flash[:alert] = error_message
    redirect_to root_path
  end
end
