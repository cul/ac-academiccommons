require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

module Auth
  # Auth::Token implements HTTP Token Authentication
  #
  # Initialize with the Rack application that you want protecting,
  # and a block that checks if a username and password pair are valid.
  class Token < Rack::Auth::AbstractHandler
    def call(env)
      auth = Token::Request.new(env)

      return unauthorized unless auth.provided?

      return bad_request unless auth.token?

      return @app.call(env) if valid?(auth)

      unauthorized
    end

    private

    def challenge
      'Token realm="%s"' % realm
    end

    def valid?(auth)
      @authenticator.call(*auth.credentials)
    end

    class Request < Rack::Auth::AbstractRequest
      def token?
        /^(token|bearer)$/ =~ scheme && !token.nil? && token.present?
      end

      def credentials
        @credentials ||= [token, params.except('token')]
      end

      def token
        @token ||= params['token']
      end

      def params
        @params ||= (parts.last || '').split(/\s*(?:,|;|\t+)\s*/).map.with_index do |part, i|
                      pair = part.split('=', 2)
                      pair.unshift('token') if i.zero? && pair.length == 1
                      pair.push('') if pair.length == 1
                      pair[1].gsub!(%r/^"|"$/, '')
                      pair
                    end.to_h
      end
    end
  end
end
