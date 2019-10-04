class LogsController < ApplicationController
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

  def download_log
    headers['Content-Type'] = 'application/octet-stream'
    headers['Content-Disposition'] = "attachment;filename=\"#{params[:id]}.log\""
    render plain: getLogContent(params[:log_folder], params[:id])
  end

  private

    def getHistoryLogs(log_folder)
      path_file_pattern = "#{Rails.root}/log/#{log_folder}/*.log"

      logs = []
      Dir.glob(path_file_pattern) do |log_file_path|
        log = {}
        log[:filepath] = log_file_path
        log[:filename] = File.basename(log_file_path)
        time_id = log[:filename].gsub(/\.log/, '')
        log[:time_id] = time_id.to_s
        log[:year] = time_id[0..3].to_i
        log[:month] = time_id[4..5].to_i
        log[:day] = time_id[6..7].to_i
        log[:hour] = time_id[9..10].to_i
        log[:minute] = time_id[11..12].to_i
        log[:second] = time_id[13..14].to_i
        log[:time] = Time.mktime(log[:year], log[:month], log[:day], log[:hour], log[:minute], log[:second]).strftime('%B %e, %Y %r')
        logs << log
      end

      logs.reverse!

      return logs

    end

    def getLogContent(log_folder, log_id)
      return File.open("#{Rails.root}/log/#{log_folder}/#{log_id}.log").read
    end
end
