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
require_relative '../../lib/academic_commons/fast_mcp/transports/managed_tokens_streamable_transport'
require_relative '../../lib/academic_commons/fast_mcp/transports/managed_tokens_transport'

def mount_in_rails(app, options = {})
  # Default options
  name = options.delete(:name) || app.class.module_parent_name.underscore.dasherize
  version = options.delete(:version) || '1.0.0'
  logger = options[:logger] || Rails.logger
  transport_type = options.delete(:transport) || FastMcp.detect_transport_type(options)

  # Handle transport-specific options
  FastMcp.setup_streamable_rails_transport(app, options.merge(name: name, version: version, logger: logger))
  path_prefix = options.delete(:path_prefix) || '/mcp'
  options[:path_prefix] = path_prefix
  options[:warn_deprecation] = true

  transport_klass = case transport_type
                    when :oauth
                      FastMcp::Transports::OAuthStreamableHttpTransport
                    when :authenticated
                      AcademicCommons::FastMcp::Transports::ManagedTokensStreamableTransport
                    else
                      FastMcp::Transports::StreamableHttpTransport
                    end

  # Create server
  FastMcp.server = FastMcp::Server.new(name: name, version: version, logger: logger)
  yield FastMcp.server if block_given?

  # Insert middleware
  app.middleware.use(
    transport_klass,
    FastMcp.server,
    options
  )
end

mount_in_rails(
  Rails.application,
  name: 'cul-academic-commons',
  version: '1.0.0',
  transport: :authenticated,
  path: '/mcp', # This is the default path prefix
  # Add allowed origins below, it defaults to Rails.application.config.hosts
  allowed_origins: ['localhost', '127.0.0.1', '::1'] + Rails.application.config.hosts,
  localhost_only: Rails.env.development?, # Set to false to allow connections from other hosts
  require_https: !Rails.env.development?,
  # whitelist specific ips to if you want to run on localhost and allow connections from other IPs
  # allowed_ips: ['127.0.0.1', '::1'],
  authenticate: true
) do |server|
  Rails.application.config.after_initialize do
    server.register_tool(RecordsTool)
  end
end
