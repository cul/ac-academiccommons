# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # This only exists to allow us to use 'redirect_to new_user_session_path' and
  # send a POST req to our omniauth endpoint (which is the secure way) (POST is
  # not possible with redirect_to)
  # https://stackoverflow.com/questions/985596/redirect-to-using-post-in-rails
  def new
    puts 'heyhyyy'
  end

  # This is needed if not using database authenticable (see https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications)
  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  def omniauth_provider_key
    Rails.env.development? ? 'developer' : 'saml' # TODO: use cas?
  end
end
