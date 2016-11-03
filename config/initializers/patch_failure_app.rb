require 'cul/omniauth/failure_app'

class Cul::Omniauth::FailureApp < Devise::FailureApp
  # def redirect_url
  #   send "user_#{self.class.provider}_omniauth_authorize_path"
  # end
  def redirect_url
    if warden_message == :timeout
      flash[:timedout] = true if is_flashing_format?

      path = if request.get?
        attempted_path
      else
        request.referrer
      end

      path || scope_url
    else
      scope_url
    end
  end
end
