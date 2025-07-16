# frozen_string_literal: true

class SiteOption < ApplicationRecord
  DEPOSITS_ENABLED = 'deposits_enabled'
  DOWNLOADS_ENABLED = 'downloads_enabled'
  OPTIONS = [DEPOSITS_ENABLED, DOWNLOADS_ENABLED].freeze
  DOWNLOADS_ENABLED_MESSAGE = 'Downloading has been temporarily disabled for Academic Commons. Contact an administrator for more information.' # rubocop:disable Layout/LineLength

  validates :name, presence: { inclusion: { in: OPTIONS } }
  validates :value, inclusion: { in: [true, false] }

  def self.downloads_enabled
    return default_value_for_option(DOWNLOADS_ENABLED) if find_by(name: DOWNLOADS_ENABLED)&.value.nil?

    find_by(name: DOWNLOADS_ENABLED)&.value
  end

  def self.deposits_enabled
    return default_value_for_option(DEPOSITS_ENABLED) if find_by(name: DEPOSITS_ENABLED)&.value.nil?

    find_by(name: DEPOSITS_ENABLED)&.value
  end

  def self.default_value_for_option(option_key)
    unless OPTIONS.include?(option_key)
      raise ArgumentError, "Invalid option key: #{option_key}. Must be one of: #{OPTIONS.join(', ')}"
    end

    return true if option_key == DOWNLOADS_ENABLED

    # options will default to false so that admins must turn the option on
    false
  end
end
