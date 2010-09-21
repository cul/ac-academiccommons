class CatalogController < ApplicationController
  after_filter :record_stats, :only => :show
  unloadable
  # before_filter :require_user
  

  def record_stats()
    Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => params["action"], :identifier => params["id"], :at_time => Time.now())
  end
end
