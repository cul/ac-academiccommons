# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :set_return_to, only: :new

  # This allows us to use 'redirect_to new_user_session_path' to render a form
  # that sends a POST req to our omniauth endpoint (this is the secure way and
  # POST is not possible with redirect_to)
  # inspiration: https://stackoverflow.com/questions/985596/redirect-to-using-post-in-rails
  def new
    render 'users/sessions/new'
  end

  # This is needed if not using database authenticable (see https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications)
  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  private

  def set_return_to
    session[:return_to] =
      if request.referer
        URI.parse(request.referer).path
      else
        root_path
      end
  rescue URI::InvalidURIError
    session[:return_to] = root_path
  end
end
