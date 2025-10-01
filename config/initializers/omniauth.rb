# frozen_string_literal: true

# OmniAuth 2+ requires explicit configuration for CSRF protection
OmniAuth.config.allowed_request_methods = [:post] if Rails.env.development?

# For development, we can be more permissive with CSRF
# if Rails.env.development?
#   OmniAuth.config.test_mode = false # Set to true if you want to use test mode
# end

# https://github.com/omniauth/omniauth/wiki/FAQ#omniauthfailureendpoint-does-not-redirect-in-development-mode
# OmniAuth.config.on_failure = proc do |env|
#   OmniAuth::FailureEndpoint.new(env).redirect_to_failure
# end
