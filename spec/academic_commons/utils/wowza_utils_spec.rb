# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcademicCommons::Utils::WowzaUtils do
  let(:bucket_mapping) do
    {
      'bucket-a': 'WOWZA_APPLICATION_NAME_A',
      'bucket-b': 'WOWZA_APPLICATION_NAME_B'
    }
  end

  let(:wowza_config) do
    {
      host: 'example.com',
      port: 1935,
      ssl_port: 8443,
      token_prefix: 'wowza',
      shared_secret: 'EXAMPLE_SECRET',
      token_lifetime: 10_800,
      application: 'EXAMPLE_APPLICATION_NAME',
      wowza_application_for_file_protocol_resources: 'WOWZA_APPLICATION_NAME_1',
      wowza_bucket_to_application_mapping_for_s3_resources: bucket_mapping
    }
  end

  let(:remote_ip) { '1.2.3.4' }
  let(:frozen_now) { Time.zone.parse('2026-01-01 00:00:00') }

  before do
    allow(Rails.application.credentials).to receive(:wowza).and_return(wowza_config)
    allow(Time).to receive(:now).and_return(frozen_now)
  end

  describe '.wowza_secure_token_params_for_file_path' do
    it 'generates the expected params, stripping the leading slash and using the file-protocol application' do
      params = described_class.wowza_secure_token_params_for_file_path(
        wowza_config, '/path/to/movie.mp4', remote_ip
      )

      expect(params).to eq(
        stream: 'WOWZA_APPLICATION_NAME_1/_definst_/mp4:path/to/movie.mp4',
        secret: 'EXAMPLE_SECRET',
        client_ip: remote_ip,
        starttime: frozen_now.to_i,
        endtime: frozen_now.to_i + 10_800,
        prefix: 'wowza'
      )
    end

    it 'uses the mp3 stream prefix when the file path ends with .mp3' do
      params = described_class.wowza_secure_token_params_for_file_path(
        wowza_config, '/path/to/movie.mp3', remote_ip
      )

      expect(params[:stream]).to eq('WOWZA_APPLICATION_NAME_1/_definst_/mp3:path/to/movie.mp3')
    end

    it 'uses the provided remote_ip when there is no client_ip_override' do
      params = described_class.wowza_secure_token_params_for_file_path(
        wowza_config, '/path/to/movie.mp4', remote_ip
      )

      expect(params[:client_ip]).to eq(remote_ip)
    end

    it 'prefers client_ip_override over remote_ip when configured' do
      wowza_config[:client_ip_override] = '10.10.10.10'

      params = described_class.wowza_secure_token_params_for_file_path(
        wowza_config, '/path/to/movie.mp4', remote_ip
      )

      expect(params[:client_ip]).to eq('10.10.10.10')
    end

    it 'sets endtime to starttime plus the configured token_lifetime' do
      wowza_config[:token_lifetime] = 60

      params = described_class.wowza_secure_token_params_for_file_path(
        wowza_config, '/path/to/movie.mp4', remote_ip
      )

      expect(params[:endtime] - params[:starttime]).to eq(60)
    end
  end

  describe '.wowza_secure_token_params_for_s3_file' do
    it 'generates the expected params, mapping the bucket to its wowza application' do
      params = described_class.wowza_secure_token_params_for_s3_file(
        wowza_config, 'bucket-a', 'folder/movie.mp4', remote_ip
      )

      expect(params).to eq(
        stream: 'WOWZA_APPLICATION_NAME_A/_definst_/mp4:WOWZA_APPLICATION_NAME_A/folder/movie.mp4',
        secret: 'EXAMPLE_SECRET',
        client_ip: remote_ip,
        starttime: frozen_now.to_i,
        endtime: frozen_now.to_i + 10_800,
        prefix: 'wowza'
      )
    end

    it 'uses the mp3 stream prefix when the object key ends with .mp3' do
      params = described_class.wowza_secure_token_params_for_s3_file(
        wowza_config, 'bucket-b', 'folder/track.mp3', remote_ip
      )

      expect(params[:stream]).to eq('WOWZA_APPLICATION_NAME_B/_definst_/mp3:WOWZA_APPLICATION_NAME_B/folder/track.mp3')
    end

    it 'maps a different bucket to its respective wowza application' do
      params = described_class.wowza_secure_token_params_for_s3_file(
        wowza_config, 'bucket-b', 'movie.mp4', remote_ip
      )

      expect(params[:stream]).to eq('WOWZA_APPLICATION_NAME_B/_definst_/mp4:WOWZA_APPLICATION_NAME_B/movie.mp4')
    end

    it 'prefers client_ip_override over remote_ip when configured' do
      wowza_config[:client_ip_override] = '10.10.10.10'

      params = described_class.wowza_secure_token_params_for_s3_file(
        wowza_config, 'bucket-a', 'movie.mp4', remote_ip
      )

      expect(params[:client_ip]).to eq('10.10.10.10')
    end

    it 'returns nil when the bucket has no configured wowza application mapping' do
      expect(
        described_class.wowza_secure_token_params_for_s3_file(
          wowza_config, 'unmapped-bucket', 'movie.mp4', remote_ip
        )
      ).to be_nil
    end
  end

  describe '.wowza_url_for_video_location' do
    let(:params_instance) { instance_double('Wowza::SecureToken::Params instance') }
    let(:secure_token_params_class) { instance_double('Wowza::SecureToken::Params class') }

    before do
      allow(Wowza::SecureToken::Params).to receive(:new).and_return(params_instance)
      allow(params_instance).to receive(:to_url_with_token_hash).and_return('https://example.com/stream/token.m3u8')
    end

    context 'with a file:// video_location_uri' do
      let(:file_path) { '/path/to/movie.mp4' }
      let(:video_location_uri) { "file://#{file_path}" }

      it 'normalizes the path to a file:// uri and calls the expected methods internally' do
        expect(described_class).to receive(:wowza_secure_token_params_for_file_path).with(
          wowza_config,
          file_path,
          remote_ip
        ).and_call_original

        expect(Wowza::SecureToken::Params).to receive(:new).with(
          hash_including(
            stream: 'WOWZA_APPLICATION_NAME_1/_definst_/mp4:path/to/movie.mp4',
            client_ip: remote_ip
          )
        ).and_return(params_instance)

        result = described_class.wowza_url_for_video_location(file_path, remote_ip)

        expect(result).to eq('https://example.com/stream/token.m3u8')
        expect(params_instance).to have_received(:to_url_with_token_hash).with('example.com', 8443, 'hls-ssl')
      end
    end

    context 'with a video_location_uri that starts with a slash (which despite not being a URI, we support anyway)' do
      let(:file_path) { '/path/to/movie.mp4' }
      let(:video_location_uri) { file_path }

      it 'normalizes the path to a file:// uri and calls the expected method internally' do
        expect(Wowza::SecureToken::Params).to receive(:new).with(
          hash_including(
            stream: 'WOWZA_APPLICATION_NAME_1/_definst_/mp4:path/to/movie.mp4',
            client_ip: remote_ip
          )
        ).and_return(params_instance)

        described_class.wowza_url_for_video_location(video_location_uri, remote_ip)
      end
    end

    context 'with an s3:// video_location_uri' do
      let(:video_location_uri) { 's3://bucket-a/folder/movie.mp4' }

      it 'normalizes the path to a file:// uri and calls the expected method internally' do
        expect(Wowza::SecureToken::Params).to receive(:new).with(
          hash_including(
            stream: 'WOWZA_APPLICATION_NAME_A/_definst_/mp4:WOWZA_APPLICATION_NAME_A/folder/movie.mp4',
            client_ip: remote_ip
          )
        ).and_return(params_instance)

        described_class.wowza_url_for_video_location(video_location_uri, remote_ip)
      end
    end

    context 'with an unsupported scheme' do
      let(:video_location_uri) { 'http://example.com/movie.mp4' }

      it 'returns nil' do
        expect(secure_token_params_class).not_to receive(:new)
        expect(described_class.wowza_url_for_video_location(video_location_uri, remote_ip)).to be_nil
      end
    end
  end
end
