# require 'cul/omniauth/failure_app'

# class Cul::Omniauth::FailureApp < Devise::FailureApp

#   # Instead of redirecting to omniauth login url, use default Devise behavior.
#   # Overriding Cul::Omniauth::FailureApp v.0.5.2 with Devise v.0.4.x implementation.
#   # TODO: Find a better way to do this.
#   def redirect_url
#     if warden_message == :timeout
#       flash[:timedout] = true if is_flashing_format?

#       path = if request.get?
#         attempted_path
#       else
#         request.referrer
#       end

#       path || scope_url
#     else
#       scope_url
#     end
#   end
# end
