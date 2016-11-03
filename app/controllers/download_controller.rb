class DownloadController < ApplicationController

#  after_filter :record_stats

  include InfoHelper
  include LogsHelper

  before_filter :require_admin!, only: :download_log


  def download_log
    headers["Content-Type"] = "application/octet-stream"
    headers["Content-Disposition"] = "attachment;filename=\"#{params[:id]}.log\""
    render :text => getLogContent(params[:log_folder], params[:id])
  end

  def fedora_content
    url = fedora_config["url"] + "/objects/" + params[:uri]+ "/datastreams/" + params[:block] + "/content"

    cl = HTTPClient.new

    head_response = cl.head(url)
    if(head_response.status != 200)
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
        xml = Nokogiri(cl.get_content(url))
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



  private

  def record_stats()
    unless is_bot?(request.user_agent)
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "Download", :identifier => params["uri"], :at_time => Time.now())
    end
  end
end
