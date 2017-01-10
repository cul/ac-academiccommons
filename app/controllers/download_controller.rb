class DownloadController < ApplicationController

#  after_filter :record_stats

  include LogsHelper

  before_filter :require_admin!, only: :download_log

  STANDARD_SEARCH_PARAMS = {
    qt: 'standard',
    fl: '*',
    fq: [],
    facet: false
  }

  def download_log
    headers["Content-Type"] = "application/octet-stream"
    headers["Content-Disposition"] = "attachment;filename=\"#{params[:id]}.log\""
    render :text => getLogContent(params[:log_folder], params[:id])
  end

  def fedora_content
    repository = Blacklight.default_index.connection
    # get the resource doc and its parent docs
    # this might be possible in one solr query if we index the info:fedora URI
    # and use a join clause on cul_member_of OR'd to the id search
    search_params = STANDARD_SEARCH_PARAMS.merge(
      q: "id:#{params[:uri].gsub(':','\:')}"
    )
    solr_results = repository.get("select", params: search_params)
    docs = solr_results['response']['docs']
    # did the resource doc exist? is it active?
    resource_doc = docs.first
    resource_doc = SolrDocument.new(resource_doc) if resource_doc
    fail_fast = resource_doc.nil? || !free_to_read?(resource_doc)

    if !fail_fast
      # are any parent docs active and readable?
      ids = resource_doc.fetch(:cul_member_of_ssim,[]).map { |val| val.split('/').last }
      ids = ids.map { |val| val.gsub(':','\:') }
      fail_fast = !any_free_to_read?(ids)
    end

    url = fedora_config["url"] + "/objects/" + params[:uri] + "/datastreams/" + params[:block] + "/content"

    # Allow descMetadata downloads of resources regardless of embargo status.
    # Allow CONTENT downloads of metadata. # TODO: Remove after Hyacinth migration.
    if (is_metadata?(resource_doc) && params[:block] == 'CONTENT') || (params[:block] == 'descMetadata')
      fail_fast = false
    end

    head_response = http_client.head(url) unless fail_fast
    fail_fast ||= (head_response.status != 200)

    if fail_fast
      render :nothing => true, :status => 404
      return
    end

    case params[:download_method]
    when "download"
      if(params[:data] != "meta")
         record_stats
      end
      headers['X-Accel-Redirect'] = x_accel_url(url)
      render :nothing => true
    when "show_pretty"
      h_ct = head_response.header["Content-Type"].to_s
      text_result = nil
      if h_ct.include?("xml")
        xsl = Nokogiri::XSLT(File.read(Rails.root.to_s + "/app/tools/pretty-print.xsl"))
        xml = Nokogiri(http_client.get_content(url))
        text_result = xsl.apply_to(xml).to_s
      else
        text_result = "Non-xml content streams cannot be pretty printed."
      end
      if params[:xml]
        headers["Content-Type"] = "text/xml"
        render :xml => text_result
      else
        headers["Content-Type"] = "text/plain"
        render :text => text_result
      end
    else
      headers['X-Accel-Redirect'] = x_accel_url(url)
      render :nothing => true
    end
  end

  def http_client
    @cl ||= HTTPClient.new
  end

#downloading of files is handed off to nginx to improve performance.
#uses the x-accel-redirect header in combination with nginx config location
#syntax ’repository_download’ to have nginx proxy the download.
#see http://kovyrin.net/2010/07/24/nginx-fu-x-accel-redirect-remote/

  def x_accel_url(url, file_name = nil)
    uri = "/repository_download/#{url.gsub(/https?\:\/\//, '')}"
    uri << "?#{file_name}" if file_name

     logger.info "=========== " + url

    return uri
  end

  # copied from AcademicCommons::Indexable
  # TODO: DRY this logic
  def free_to_read?(document)
    return false unless document['object_state_ssi'] == 'A'
    free_to_read_start_date = document[:free_to_read_start_date]
    return true unless free_to_read_start_date
    embargo_release_date = Date.strptime(free_to_read_start_date, '%Y-%m-%d')
    current_date = Date.strptime(Time.now.strftime('%Y-%m-%d'), '%Y-%m-%d')
    current_date > embargo_release_date
  end

  def any_free_to_read?(ids)
    return false if ids.blank?
    repository = Blacklight.default_index.connection
    search_params = STANDARD_SEARCH_PARAMS.merge(
      q: "id:(#{ids.join(' OR ')})"
    )
    solr_results = repository.get("select", params: search_params)
    docs = solr_results['response']['docs'].map { |d| SolrDocument.new(d) }
    docs.detect { |d| free_to_read?(d) }
  end

  private

  # TODO: Remove after Hyacinth migration.
  def is_metadata?(doc)
    doc.nil? || (doc['has_model_ssim'] && doc['has_model_ssim'].include?('info:fedora/ldpd:MODSMetadata'))
  end

  def record_stats
    unless is_bot?(request.user_agent)
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "Download", :identifier => params["uri"], :at_time => Time.now())
    end
  end
end
