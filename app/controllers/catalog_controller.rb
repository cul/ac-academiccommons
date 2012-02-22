# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  
  before_filter :record_stats, :only => :show
  unloadable
 
  before_filter :redirect_browse
  before_filter :url_decode_f
  
  helper_method :url_encode_resource, :url_decode_resource
  
  # displays values and pagination links for a single facet field
  def facet
    @pagination = get_facet_pagination(params[:id], params)
    render :layout => false
  end
  
  def browse
    render :layout => "catalog_browse"
  end
  
  def browse_department
    render :layout => "catalog_browse"
  end
  
  def browse_subject
    index
  end
  
  def redirect_browse
    
    if(params[:id].to_s == 'browse')
      redirect_to :action => 'browse', :id => 'subjects'
    end
    
  end
  
  def url_decode_f
    if(params && params[:f])
      params[:f].each do |name, values|
        i = 0
        values.each do |value|
          params[:f][name][i] = url_decode_resource(value)
          i = i + 1
        end
      end
    end
  end
  
  def url_encode_resource(value)
    value = CGI::escape(value).gsub(/%2f/i, '%252F').gsub(/\./, '%2E')
  end
  
  def url_decode_resource(value)
    value = value.gsub(/%252f/i, '%2F').gsub(/%2e/i, '.')
    value = CGI::unescape(value)
  end
  
  private
  
  def record_stats()
      unless StatSupport::is_bot?(request.user_agent)
       Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "View", :identifier => params["id"], :at_time => Time.now())
      end
  end
end 
