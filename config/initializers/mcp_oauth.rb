# frozen_string_literal: true

MCP_METADATA = MCP::Server::OAuth::ProtectedResourceMetadata.new(
  resource: Rails.application.config_for(:mcp)[:resource],
  authorization_servers: Rails.application.config_for(:mcp)[:authorization_servers],
  scopes_supported: Rails.application.config_for(:mcp)[:scopes]
)

MCP_VERIFIER = MCP::Server::OAuth::IntrospectionVerifier.new(
  resource_metadata: MCP_METADATA,
  introspection_endpoint: Rails.application.config_for(:mcp)[:introspection_endpoint],
  client_id: Rails.application.config_for(:mcp)[:client_id],
  client_secret: Rails.application.config_for(:mcp)[:client_secret]
)

Rails.application.config.middleware.use(MCP::Server::OAuth::ProtectedResourceMetadataMiddleware, MCP_METADATA)
