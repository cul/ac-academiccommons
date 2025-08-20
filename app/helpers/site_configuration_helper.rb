# frozen_string_literal: true

module SiteConfigurationHelper
  def alert_message?
    SiteConfiguration.alert_message.present?
  end

  def downloads_enabled?
    SiteConfiguration.downloads_enabled
  end

  def deposits_enabled?
    SiteConfiguration.deposits_enabled
  end
end
