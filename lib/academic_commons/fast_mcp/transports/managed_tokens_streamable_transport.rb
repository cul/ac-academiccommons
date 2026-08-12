# frozen_string_literal: true

module AcademicCommons
  module FastMcp
    module Transports
      class ManagedTokensStreamableTransport < ::FastMcp::Transports::AuthenticatedStreamableHttpTransport
        def auth_enabled?
          true
        end

        def valid_token?(token)
          Token.find_by(token: token, scope: Token::API)
        end
      end
    end
  end
end
