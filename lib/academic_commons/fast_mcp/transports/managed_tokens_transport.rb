# frozen_string_literal: true

module AcademicCommons
  module FastMcp
    module Transports
      class ManagedTokensTransport < ::FastMcp::Transports::AuthenticatedRackTransport
        def valid_token?(token)
          Token.find_by(token: token, scope: Token::API)
        end
      end
    end
  end
end
