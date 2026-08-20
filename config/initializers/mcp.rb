# frozen_string_literal: true

MCP.configure do |config|
  config.exception_reporter = lambda { |exception, server_context|
    Rails.logger.error({ mcp_error: "#{exception.class}: #{exception.message}",
                         context: server_context,
                         backtrace: exception.backtrace }.to_json)
  }
end
