# frozen_string_literal: true

module AcademicCommons::Utils::WowzaUtils
  def self.wowza_url_for_video_location(video_location_uri, remote_ip) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # Normalize file paths into file URIs
    video_location_uri = "file://#{video_location_uri}" if video_location_uri.start_with?('/')

    wowza_config = Rails.application.credentials.wowza
    if wowza_config.nil?
      Rails.logger.error 'Wowza config not found in credentials file.'
      return nil
    end

    # Select the correct wowza config base on the location protocol (file vs. s3)
    uri = URI(video_location_uri)
    wowza_secure_token_params = case uri.scheme
                                when 'file'
                                  wowza_secure_token_params_for_file_path(wowza_config, uri.path, remote_ip)
                                when 's3'
                                  wowza_secure_token_params_for_s3_file(wowza_config, uri.host,
                                                                        uri.path.gsub(%r{^/}, ''), remote_ip)
                                end

    return nil if wowza_secure_token_params.nil?

    Wowza::SecureToken::Params.new(wowza_secure_token_params).to_url_with_token_hash(wowza_config[:host],
                                                                                     wowza_config[:ssl_port], 'hls-ssl')
  end

  def self.wowza_secure_token_params_for_file_path(wowza_config, file_path, remote_ip)
    {
      stream: "#{wowza_config[:wowza_application_for_file_protocol_resources]}/_definst_/"\
              "#{file_path.downcase.end_with?('.mp3') ? 'mp3:' : 'mp4:'}#{file_path.gsub(%r{^/}, '')}",
      secret: wowza_config[:shared_secret],
      client_ip: wowza_config[:client_ip_override] || remote_ip,
      starttime: Time.now.to_i,
      endtime: Time.now.to_i + wowza_config[:token_lifetime].to_i,
      # Important: token_prefix in Wowza application should always be 'wowza' (see: UNIX-5941)
      prefix: wowza_config[:token_prefix]
    }
  end

  def self.wowza_secure_token_params_for_s3_file(wowza_config, bucket_name, object_key, remote_ip) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    wowza_application = wowza_config.dig(:wowza_bucket_to_application_mapping_for_s3_resources, bucket_name.to_sym)

    if wowza_application.nil?
      Rails.logger.error "Unable to map bucket_name #{bucket_name} to wowza application. Check wowza config."
      return nil
    end

    {
      stream: "#{wowza_application}/_definst_/#{object_key.downcase.end_with?('.mp3') ? 'mp3:' : 'mp4:'}"\
              "#{wowza_application}/#{object_key}",
      secret: wowza_config[:shared_secret],
      client_ip: wowza_config[:client_ip_override] || remote_ip,
      starttime: Time.now.to_i,
      endtime: Time.now.to_i + wowza_config[:token_lifetime].to_i,
      # Important: token_prefix in Wowza application should always be 'wowza' (see: UNIX-5941)
      prefix: wowza_config[:token_prefix]
    }
  end
end
