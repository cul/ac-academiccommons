# frozen_string_literal: true

class McpController < ActionController::API
  # Disabling ot use oauth middleware instead
  # before_action :authenticate_api_token!

  def create
    server = MCP::Server.new(
      name: 'cul-academic-commons',
      version: '1.0.0',
      tools: [RecordsTool]
    )
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true,
      allowed_hosts: Rails.application.config.hosts.map(&:to_s),
      serve_subscriptions_listen: false,
      token_verifier: MCP_VERIFIER,
      required_scopes: Rails.application.config_for(:mcp)[:scopes],
      resource_metadata: MCP_METADATA
    )
    status, headers, body = transport.handle_request(request)

    render(json: body.first, status: status, headers: headers)
  end

  private

  def authenticate_api_token!
    req_token = request.headers['Authorization'].to_s.gsub('Bearer ', '')
    api_token = Token.find_by(token: req_token, scope: Token::MCP)
    render(json: { error: 'Unauthorized' }, status: :unauthorized) if req_token.nil? || api_token.nil?
  end
end
