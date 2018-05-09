class LogsController < ApplicationController
  include LogsHelper

  authorize_resource class: false
  layout 'admin'

  def ingest_history
    @log_folder = 'ac-indexing'
    @title = 'Ingest History'
    @logs = getHistoryLogs(@log_folder)
    render template: 'logs/log_history'
  end

  def all_author_monthly_reports_history
    @log_folder = 'monthly_reports'
    @title = 'Monthly Reports History'
    @logs = getHistoryLogs(@log_folder)
    render template: 'logs/log_history'
  end

  def log_form
    log_content = getLogContent(params[:log_folder], params[:log_id])

    render template: 'logs/log_form', layout: false,
           locals: { log_content: log_content.to_s }
  end
end
