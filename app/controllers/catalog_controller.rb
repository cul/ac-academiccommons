class CatalogController < ApplicationController
  before_filter :record_stats, :only => :show
  unloadable
  # before_filter :require_user
 
  before_filter :redirect_browse
  before_filter :url_decode_f

  
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
      params[:f].each do |name, value|
        i = 0
        value.each do |each_value|
          params[:f][name][i] = @template.url_decode_resource(each_value)
          i = i + 1
        end
      end
    end
  end
  
  private
  
  def record_stats()
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "View", :identifier => params["id"], :at_time => Time.now())
  end
  
end
