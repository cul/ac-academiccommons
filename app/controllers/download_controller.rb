class DownloadController < ApplicationController
  
  after_filter :record_stats
  
  def fedora_content
      
    url = fedora_config["riurl"] + "/get/" + params[:uri]+ "/" + params[:block]

    cl = HTTPClient.new
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    h_ct = cl.head(url).header["Content-Type"].to_s
    text_result = nil

    case params[:download_method]
    when "download"
      h_cd = "attachment; " + h_cd 
    when "show_pretty"
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
        
      headers["Content-Disposition"] = h_cd
      headers["Content-Type"] = h_ct

      
      send_data(cl.get_content(url), :filename => CGI.escapeHTML(params[:filename].to_s), :type => h_ct)
      
    end
  end

  private
  
  def record_stats()
    Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "Download", :identifier => params["uri"], :at_time => Time.now())
  end
  
end


