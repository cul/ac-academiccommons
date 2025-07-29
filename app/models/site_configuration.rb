# frozen_string_literal: true

class SiteConfiguration < ApplicationRecord
  # The singleton_gaurd column is a unique column that must be set to 0
  # This ensures that only one record of type SiteConfiguration is ever created
  # (via https://stackoverflow.com/questions/399447/how-to-implement-a-singleton-model)
  validates :singleton_gaurd, inclusion: { in: [0] }

  DOWNLOADS_ENABLED_DEF = true
  DEPOSITS_ENABLED_DEF = true
  DOWNLOADS_ENABLED_MESSAGE_DEF = 'Downloading has been temporarily disabled for Academic Commons. Contact an administrator for more information.' # rubocop:disable Layout/LineLength

  # DEPOSITS_ENABLED = 'deposits_enabled'
  # DOWNLOADS_ENABLED = 'downloads_enabled'
  # OPTIONS = [DEPOSITS_ENABLED, DOWNLOADS_ENABLED, ALERT_MESSAGE].freeze
  # DEPOSITS_ENABLED_DEF_MESSAGE = 'deposits site option default message'

  def self.instance
    where(singleton_gaurd: 0).first_or_create! do |site_config|
      site_config.downloads_enabled = DOWNLOADS_ENABLED_DEF
      site_config.downloads_message = DOWNLOADS_ENABLED_MESSAGE_DEF
      site_config.deposits_enabled = DEPOSITS_ENABLED_DEF
      site_config.alert_message = ''
      site_config.singleton_gaurd = 0
    end
  end

  def self.downloads_enabled
    instance.downloads_enabled
  end

  def self.downloads_message
    instance.downloads_message
  end

  def self.deposits_enabled
    instance.deposits_enabled
  end

  def self.alert_message
    instance.alert_message
  end
end
