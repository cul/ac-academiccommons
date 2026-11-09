# frozen_string_literal: true

class RecordsTool < MCP::Tool
  title 'Academic Commons Works Search'
  description 'Find works in Academic Commons'
  tool_name 'RecordsTool'

  # Optional: Add annotations to provide hints about the tool's behavior
  annotations(
    title: 'Academic Commons Works Search',
    read_only_hint: true,      # This tool only reads data
    open_world_hint: false     # This tool only accesses the local database
  )

  input_schema(
    properties: {
      search_type: {
        type: 'string', enum: %w[keyword semantic subject title],
        description:
          'type of search to use; use \'semantic\' for natural language queries, or \'keyword\' for term matching'
      },
      q: { type: 'string', description: 'query string' },
      page: { type: 'integer', minimum: 1, description: 'page number' },
      per_page: { type: 'integer', minimum: 1, maximum: 100,
                  description: 'number of results returned per page; the maximum number of results is 100' },
      sort: { type: 'string', enum: V1::Helpers::Solr::SORT.map(&:to_s), description: 'sorting of search results' },
      order: { type: 'string', enum: V1::Helpers::Solr::ORDER.map(&:to_s), description: 'ordering of results' }
    },
    required: []
  )

  # rubocop:disable Lint/UnusedMethodArgument
  def self.call(server_context:, search_type: 'semantic', q: nil,
                page: 1, per_page: 25, sort: 'best_match', order: 'desc')
    response = AcademicCommons::RecordSearch.call(
      search_type: search_type.to_sym, q: q,
      page: page.to_i, per_page: per_page.to_i,
      sort: sort.to_sym, order: order.to_sym
    )
    MCP::Tool::Response.new([{ type: 'text', text: response }])
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
