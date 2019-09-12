class ContentBlock < ApplicationRecord
  ALERT_MESSAGE = 'alert_message'.freeze

  validates :title, :user, presence: true
  validates :title, uniqueness: true

  belongs_to :user
end
