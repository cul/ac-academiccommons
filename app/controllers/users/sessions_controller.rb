class Users::SessionsController < Devise::SessionsController
  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  def omniauth_provider_key
    Rails.env.development? ? 'developer' : 'saml'
  end

  # GET /resource/sign_in
  def new
    preface = "--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=\n"
    puts "#{preface} RAILS ENV IS DEV? -> #{Rails.env.development?}"
    if Rails.env.development?
      puts "#{preface} redirect to user_developer_omniauth_authorize_path (users/omniauth_callbacks#passthru)"
      redirect_to user_developer_omniauth_authorize_path
    else
      redirect_to user_saml_omniauth_authorize_path
    end
  end
end
