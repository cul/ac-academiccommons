# frozen_string_literal: true

# From omniauth-cul v0.3.0 Readme
# Mitigate CVE-2015-9284
OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
