class AssetsController < ApplicationController
  include AcademicCommons::Embargoes

  before_action :load_asset

  def embed
    if restricted? # TODO: check that is is playable content here or should that check be later?
      render body: nil, status: 404
    else
      response.headers.delete 'X-Frame-Options'
      render layout: 'embed'
    end
  end

  def download
    if restricted? || !content_datastream?
      render body: nil, status: 404
    else
      record_stats
      headers['X-Accel-Redirect'] = x_accel_url(ds_content_url('content'), @asset.filename)
      render body: nil
    end
  end

  def captions
    if restricted? || !captions_datastream?
      render body: nil, status: 404
    else
      record_stats
      headers['X-Accel-Redirect'] = x_accel_url(ds_content_url('captions'), 'captions.vtt')
      render body: nil
    end
  end

  def legacy_fedora_content
    # did the resource doc exist?
    if @asset.nil?
      render body: nil, status: 404
    else
      redirect_to content_download_url(@asset.id), status: :moved_permanently
    end
  end

  private

  def load_asset
    solr_response = AcademicCommons.search do |p|
      action_name == 'legacy_fedora_content' ? p.filter('fedora3_pid_ssi', params[:uri]) : p.id(params[:id])
      p.assets_only
      p.rows 1
    end
    @asset = solr_response.docs.first
  end

  # Returns true if asset is restricted or if it does not exist.
  def restricted?
    fail_fast = @asset.nil? || @asset.embargoed?

    unless fail_fast # check that at least one of the parent docs is active and readable
      ids = @asset.fetch(:cul_member_of_ssim, [])
                  .map { |val| val.split('/').last.gsub(':', '\:') }
      fail_fast = !any_free_to_read?(ids)
    end

    fail_fast
  end

  def content_datastream?
    # TODO: can be refactored after a general reindex of assets to use datastreams_ssim
    HTTP.head(ds_content_url('content')).code == 200
  end

  def ds_content_url(dsid)
    Rails.application.config_for(:fedora)['url'] + '/objects/' + @asset.fetch(:fedora3_pid_ssi, nil) + '/datastreams/' + dsid + '/content'
  end

  def captions_datastream?
    @asset.fetch(:datastreams_ssim, []).include?('captions')
  end

  # Downloading of files is handed off to nginx to improve performance.
  # Uses the x-accel-redirect header in combination with nginx config location
  # syntax `repository_download` to have nginx proxy the download.
  # See http://kovyrin.net/2010/07/24/nginx-fu-x-accel-redirect-remote/
  def x_accel_url(url, filename = nil)
    uri = "/repository_download/#{url.gsub(/https?\:\/\//, '')}"
    uri << "?#{filename}" if filename

    logger.info '=========== ' + url

    uri
  end

  # Returns true if any of the ids are free to read.
  def any_free_to_read?(ids)
    return false if ids.blank?

    solr_response = AcademicCommons.search do |p|
      p.filter 'fedora3_pid_ssi', "(#{ids.join(' OR ')})"
    end
    @items = solr_response.docs
    @items.find { |d| !d.embargoed? }
  end

  def record_stats
    return if is_bot?(request.user_agent)
    Statistic.create!(
      session_id: request.session_options[:id],
      ip_address: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr,
      event: 'Download', identifier: params['id'], at_time: Time.current
    )
  end
end
