# frozen_string_literal: true

# OmniAuth 2+ requires explicit configuration for CSRF protection
OmniAuth.config.allowed_request_methods = [:post, :get]

# For development, we can be more permissive with CSRF
if Rails.env.development?
  OmniAuth.config.test_mode = false # Set to true if you want to use test mode
end
