class ContentBlock < ApplicationRecord
  ALERT_MESSAGE = 'alert_message'.freeze

  validates_presence_of :title
  validates_presence_of :user

  belongs_to :user

  validates_uniqueness_of :title
end
