module LogsHelper

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
      log[:time] = Time.mktime(log[:year], log[:month], log[:day], log[:hour], log[:minute], log[:second]).strftime("%B %e, %Y %r")
      logs << log 
    end
    
    logs.reverse!
    
    return logs
    
  end
  
  def getLogContent(log_folder, log_id)
    return File.open("#{Rails.root}/log/#{log_folder}/#{log_id}.log").read
  end
  
end # ==================================================== #