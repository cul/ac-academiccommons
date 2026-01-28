# frozen_string_literal: true

# SiteConfiguration is a "Singleton" Model: only one record will ever exist in
# the database, and when more site configuration options are added, they will be
# added as columns for this single record.
# Access the Site Configuration object by calling SiteConfiguration::instance,
# like you would if accessing a typical singleton class in Ruby
class SiteConfiguration < ApplicationRecord
  SINGLETON_GUARD_VALUE = 0
  DOWNLOADS_DISABLED_MESSAGE_DEFAULT = 'Downloading has been temporarily disabled for Academic Commons. Contact an administrator for more information.' # rubocop:disable Layout/LineLength

  # The singleton_guard column is a unique column that must be set to 0
  # This ensures that only one record of type SiteConfiguration is ever created
  # (via https://stackoverflow.com/questions/399447/how-to-implement-a-singleton-model)
  validates :singleton_guard, inclusion: { in: [SINGLETON_GUARD_VALUE] }, presence: true
  validates :downloads_enabled, inclusion: { in: [true, false] }
  validates :deposits_enabled, inclusion: { in: [true, false] }

  # If there is no site configuration record in the database, we create one with
  # the default values in the block passed to first_or_create
  # todo : look into caching this in "The Rails Cache"
  def self.instance
    where(singleton_guard: 0).first_or_create! do |site_config|
      site_config.downloads_enabled = true
      site_config.downloads_message = DOWNLOADS_DISABLED_MESSAGE_DEFAULT
      site_config.deposits_enabled = true
      site_config.alert_message = ''
      site_config.singleton_guard = SINGLETON_GUARD_VALUE
    end
  end

  def self.downloads_enabled
    instance.downloads_enabled
  end

  def self.downloads_message
    return DOWNLOADS_DISABLED_MESSAGE_DEFAULT if instance.downloads_message == ''

    instance.downloads_message
  end

  def self.deposits_enabled
    instance.deposits_enabled
  end

  def self.alert_message
    instance.alert_message
  end
end
