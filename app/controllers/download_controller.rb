class DownloadController < ApplicationController
  
#  after_filter :record_stats
  
  def fedora_content
      
    url = fedora_config["riurl"] + "/get/" + params[:uri]+ "/" + params[:block]
    text_result = nil

    case params[:download_method]
    when "download"
      if(params[:data] != "meta")
         record_stats
      end 
   when "show_pretty"
      cl = HTTPClient.new
      h_ct = cl.head(url).header["Content-Type"].to_s
      if h_ct.include?("xml")
        xsl = Nokogiri::XSLT(File.read(Rails.root.to_s + "/app/tools/pretty-print.xsl"))
        xml = Nokogiri(cl.get_content(url))
        text_result = xsl.apply_to(xml).to_s
      else
        text_result = "Non-xml content streams cannot be pretty printed."
      end
    end

    if text_result
      headers["Content-Type"] = "text/plain"
      render :text => text_result
    else  
      headers['X-Accel-Redirect'] = x_accel_url(url, CGI.escapeHTML(params[:filename].to_s))
      render :nothing => true
    end
  end


  def x_accel_url(url, file_name = nil)
    uri = "/repository_download/#{url.gsub('https://', '')}"
    uri << "?#{file_name}" if file_name
    return uri
  end


  private
  
  def record_stats()
    unless StatSupport::is_bot?(request.user_agent)
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "Download", :identifier => params["uri"], :at_time => Time.now())
    end
  end
end


