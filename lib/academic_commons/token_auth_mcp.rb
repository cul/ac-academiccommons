# frozen_string_literal: true

# A Rack middleware that authenticates a request's token before handing off to the
# streamable HTTP transport MCP server
module AcademicCommons
  class TokenAuthMcp
    def initialize(app)
      @app = app
    end

    def call(env)
      req_token = Rack::Request.new(env).get_header('HTTP_AUTHORIZATION').to_s.gsub('Bearer ', '')
      api_token = Token.find_by(token: req_token, scope: Token::API)

      return unauthorized_response if req_token.nil? || api_token.nil?

      @app.call(env)
    end

    def unauthorized_response
      body = { error: 'Unauthorized' }.to_json
      [401, { 'Content-Type' => 'application/json' }, [body]]
    end
  end
end
