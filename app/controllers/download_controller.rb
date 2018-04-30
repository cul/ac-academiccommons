class DownloadController < ApplicationController
  include LogsHelper
  include AcademicCommons::Embargoes

  before_action :require_admin!, only: :download_log

  STANDARD_SEARCH_PARAMS = {
    qt: 'search',
    fl: '*',
    facet: false
  }.freeze

  def download_log
    headers['Content-Type'] = 'application/octet-stream'
    headers['Content-Disposition'] = "attachment;filename=\"#{params[:id]}.log\""
    render plain: getLogContent(params[:log_folder], params[:id])
  end

  def content
    # TODO: check that we are only downloading assets?
    search_params = STANDARD_SEARCH_PARAMS.merge(
      fq: ["id:\"#{params[:id]}\""]
    )
    docs = Blacklight.default_index.search(search_params).docs
    # did the resource doc exist? is it active?
    resource_doc = docs.first
    fail_fast = resource_doc.nil? || resource_doc.embargoed?

    if !fail_fast # check that at least one of the parent docs is active and readable
      ids = resource_doc.fetch(:cul_member_of_ssim,[]).map { |val| val.split('/').last }
      ids = ids.map { |val| val.gsub(':','\:') }
      fail_fast = !any_free_to_read?(ids)
    end

    if !fail_fast # check that the content datastream exists for this object in fedora
      url = Rails.application.config_for(:fedora)['url'] + '/objects/' + resource_doc.fetch(:fedora3_pid_ssi, nil) + '/datastreams/content/content'
      head_response = http_client.head(url)
      fail_fast ||= (head_response.status != 200)
    end

    if fail_fast
      render body: nil, status: 404
    else
      record_stats
      headers['X-Accel-Redirect'] = x_accel_url(url, resource_doc.filename)
      render body: nil
    end
  end

  def legacy_fedora_content
    # Get the resource doc and its parent docs.
    search_params = STANDARD_SEARCH_PARAMS.merge(
      fq: ["fedora3_pid_ssi:\"#{params[:uri]}\""]
    )
    solr_response = Blacklight.default_index.search(search_params)
    resource_doc = solr_response.docs.first

    # did the resource doc exist?
    if resource_doc.nil?
      render body: nil, status: 404
    else
      redirect_to asset_download_url(resource_doc.id), status: :moved_permanently
    end
  end

  private

  def http_client
    @cl ||= HTTPClient.new
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
    search_params = STANDARD_SEARCH_PARAMS.merge(
      q: "fedora3_pid_ssi:(#{ids.join(' OR ')})"
    )
    solr_response = Blacklight.default_index.search(search_params)
    solr_response.docs.find { |d| !d.embargoed? }
  end

  def record_stats
    return if is_bot?(request.user_agent)
    Statistic.create!(
      session_id: request.session_options[:id],
      ip_address: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr,
      event: 'Download', identifier: params['id'], at_time: Time.now()
    )
  end
end
