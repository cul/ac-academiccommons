# frozen_string_literal: true

MCP.configure do |config|
  config.exception_reporter = lambda { |exception, server_context|
    Rails.logger.error "[MCP]: #{exception.class}: #{server_context} "
  }
end
