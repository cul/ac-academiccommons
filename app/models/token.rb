class Token < ApplicationRecord
  DATAFEED = :data_feed
  API = :api
  SCOPES = [API, DATAFEED].map(&:to_s).freeze
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
end
