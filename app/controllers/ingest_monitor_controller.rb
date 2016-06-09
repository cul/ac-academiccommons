class IngestMonitorController < ApplicationController
  before_filter :require_admin

  def show
    raise "You must include the log ID" unless params[:id]

    log_path = "#{Rails.root}/log/ac-indexing/#{params[:id]}.log"
    raise "Can't find log file #{params[:id]}.log" unless FileTest.exists?(log_path)

    log_content = `tail #{log_path}`

    respond_to do |format|
      format.html { render :layout => false, :text => '{ "log": ' + ActiveSupport::JSON.encode(log_content) + ' }' }
    end
  end
end