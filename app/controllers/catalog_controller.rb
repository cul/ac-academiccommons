class CatalogController < ApplicationController
  before_filter :record_stats, :only => :show
  unloadable
  # before_filter :require_user
  before_filter :redirect_browse

  
  def browse
    index
  end
  
  def browse_department
    index
  end
  
  def browse_subject
    index
  end
  
  def redirect_browse
    
    if(params[:id].to_s == 'browse')
      redirect_to :action => 'browse', :id => 'subjects'
    end
    
  end
  
  private
  
  def record_stats()
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "View", :identifier => params["id"], :at_time => Time.now())
  end
  
end
