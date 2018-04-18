class Token < ActiveRecord::Base
  DATAFEED = :data_feed
  SCOPES = [DATAFEED]

  validates :scope, presence: true
  validates :token, presence: true, uniqueness: true

  def self.generate_token
    SecureRandom.hex(13)
  end
end
