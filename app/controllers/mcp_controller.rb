# frozen_string_literal: true

class McpController < ActionController::API
  before_action :authenticate_api_token!

  def create
    server = MCP::Server.new(
      name: 'cul-academic-commons',
      version: '1.0.0',
      tools: [RecordsTool],
      server_context: { auth: 'information' }
    )
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true
    )
    status, headers, body = transport.handle_request(request)

    render(json: body.first, status: status, headers: headers)
  end

  private

  def authenticate_api_token!
    req_token = request.headers['Authorization']
    api_token = Token.find_by(token: req_token, scope: Token::API)
    render(json: { error: 'Unauthorized' }, status: :unauthorized) if api_token.nil?
  end
end
