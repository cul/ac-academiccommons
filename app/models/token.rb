class Token < ApplicationRecord
  DATAFEED = :data_feed
  API = :api
  MCP = :mcp
  SCOPES = [API, DATAFEED, MCP].map(&:to_s).freeze
  AUTHORIZABLE_TYPE_USER = :User
  AUTHORIZABLE_TYPE_API_CLIENT = :APIClient
  AUTHORIZABLE_TYPES = [AUTHORIZABLE_TYPE_USER, AUTHORIZABLE_TYPE_API_CLIENT].map(&:to_s).freeze

  belongs_to :authorizable, polymorphic: true

  validates :scope, inclusion: { in: SCOPES }
  validates :token, presence: true, uniqueness: true
  validates :authorizable_id, presence: true
  validates :authorizable_type, inclusion: { in: AUTHORIZABLE_TYPES }

  def self.generate_token
    SecureRandom.hex(13)
  end

  def expired? = (self.created_at - 365) < (DateTime.now - 365)

  # Tokens are valid if:
  # - they exist in the DB under the correct scope
  # - they have not reached their 1 year expiration date
  def self.valid_token?(token_str, scope)
    match = Token.find_by(token: token_str, scope: scope)
    return false if match.nil?

    !match.expired?
  end
end
