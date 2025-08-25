module Hyacinth
  def self.base_url
    url = Rails.application.config_for(:secrets).hyacinth.dig(:url)
    url.blank? ? raise(ArgumentError, 'Hyacinth URL not provided in config.') : url.to_s
  end

  def self.digital_object_url(pid)
    Addressable::URI.join(base_url, '/digital_objects#{"controller":"digital_objects","action":"show","pid":"' + pid + '"}').to_s
  end
end
