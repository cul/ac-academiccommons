# frozen_string_literal: true

class SiteOption < ApplicationRecord
  DEPOSITS_ENABLED = 'deposits_enabled'
  OPTIONS = [DEPOSITS_ENABLED].freeze

  validates :name, presence: { inclusion: { in: OPTIONS } }
  validates :value, inclusion: { in: [true, false] }

  def self.deposits_enabled
    find_by(name: DEPOSITS_ENABLED)&.value
  end
end
