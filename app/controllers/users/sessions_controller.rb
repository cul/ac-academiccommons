# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # This allows us to use 'redirect_to new_user_session_path' to render a form
  # that sends a POST req to our omniauth endpoint (this is the secure way and
  # POST is not possible with redirect_to)
  # inspiration: https://stackoverflow.com/questions/985596/redirect-to-using-post-in-rails
  def new
    store_omniauth_origin # for sign_in_and_redirect redirection
    render 'users/sessions/new'
  end

  # This is needed if not using database authenticable (see https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications)
  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  def omniauth_provider_key
    Rails.env.development? ? 'developer' : 'saml' # TODO: use cas?
  end

  private

  def store_omniauth_origin
    origin = request.params['origin'] || request.referer || root_path
    session['after_sign_in_path'] = origin
  end
end
