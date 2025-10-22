# frozen_string_literal: true

# FastMcp - Model Context Protocol for Rails
# This initializer sets up the MCP middleware in your Rails application.
#
# In Rails applications, you can use:
# - ActionTool::Base as an alias for FastMcp::Tool
# - ActionResource::Base as an alias for FastMcp::Resource
#
# All your tools should inherit from ApplicationTool which already uses ActionTool::Base,
# and all your resources should inherit from ApplicationResource which uses ActionResource::Base.

# Mount the MCP middleware in your Rails application
# You can customize the options below to fit your needs.
require 'fast_mcp'
require_relative '../../lib/academic_commons/fast_mcp/transports/managed_tokens_transport'

def mount_in_rails(app, options = {})
  # Default options
  name = options.delete(:name) || app.class.module_parent_name.underscore.dasherize
  version = options.delete(:version) || '1.0.0'
  logger = options[:logger] || Rails.logger
  path_prefix = options.delete(:path_prefix) || '/mcp'
  messages_route = options.delete(:messages_route) || 'messages'
  sse_route = options.delete(:sse_route) || 'sse'
  authenticate = options.delete(:authenticate) || false
  allowed_origins = options[:allowed_origins] || FastMcp.default_rails_allowed_origins(app)
  allowed_ips = options[:allowed_ips] || FastMcp::Transports::RackTransport::DEFAULT_ALLOWED_IPS

  options[:localhost_only] = Rails.env.development? if options[:localhost_only].nil?
  options[:allowed_ips] = allowed_ips
  options[:logger] = logger
  options[:allowed_origins] = allowed_origins

  # Create or get the server
  FastMcp.server = FastMcp::Server.new(name: name, version: version, logger: logger)
  yield FastMcp.server if block_given?

  # Choose the right middleware based on authentication
  FastMcp.server.transport_klass =
    authenticate ? AcademicCommons::FastMcp::Transports::ManagedTokensTransport : FastMcp::Transports::RackTransport

  # Insert the middleware in the Rails middleware stack
  app.middleware.use(
    FastMcp.server.transport_klass,
    FastMcp.server,
    options.merge(path_prefix: path_prefix, messages_route: messages_route, sse_route: sse_route)
  )
end

mount_in_rails(
  Rails.application,
  name: 'cul-academic-commons',
  version: '1.0.0',
  path_prefix: '/mcp', # This is the default path prefix
  messages_route: 'messages', # This is the default route for the messages endpoint
  sse_route: 'sse', # This is the default route for the SSE endpoint
  # Add allowed origins below, it defaults to Rails.application.config.hosts
  # allowed_origins: ['localhost', '127.0.0.1', '[::1]', 'example.com', /.*\.example\.com/],
  # localhost_only: true, # Set to false to allow connections from other hosts
  # whitelist specific ips to if you want to run on localhost and allow connections from other IPs
  # allowed_ips: ['127.0.0.1', '::1'],
  authenticate: true
) do |server|
  Rails.application.config.after_initialize do
    server.register_tool(RecordsTool)
  end
end
