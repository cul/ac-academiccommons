# frozen_string_literal: true

class SiteOption < ApplicationRecord
  DEPOSITS_ENABLED = 'deposits_enabled'
  DOWNLOADS_ENABLED = 'downloads_enabled'
  OPTIONS = [DEPOSITS_ENABLED, DOWNLOADS_ENABLED].freeze

  validates :name, presence: { inclusion: { in: OPTIONS } }
  validates :value, inclusion: { in: [true, false] }

  def self.downloads_enabled
    find_by(name: DOWNLOADS_ENABLED)&.value
  end

  def self.deposits_enabled
    find_by(name: DEPOSITS_ENABLED)&.value
  end

  def self.default_value_for_option(option_key)
    unless OPTIONS.include?(option_key)
      raise ArgumentError, "Invalid option key: #{option_key}. Must be one of: #{OPTIONS.join(', ')}"
    end

    return true if option_key == downloads_enabled

    # options will default to false so that admins must turn the option on
    false
  end
end
