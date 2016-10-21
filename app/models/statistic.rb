class Statistic < ActiveRecord::Base
  VIEW_EVENT = 'View'
  DOWNLOAD_EVENT = 'Download'
  STREAM_EVENT = 'Streaming'

  def self.reset_downloads
    Statistic.find_all_by_event("Download").each { |e| e.delete }

    fedora_download_match = /^([\d\.]+).+\[([^\]]+)\].+download\/fedora_content\/\w+\/([^\/]+)/
    startdate = DateTime.parse("5/1/2011")

    count = 0
    File.open(File.join("tmp", "access.log")).each_with_index do |line, i|

      if (match = fedora_download_match.match(line))
        pid = match[3].gsub("%3A", ":")
        datetime = DateTime.parse(match[2].sub(":", " "))
        ip = match[1]

        if pid.include?("ac")
          Statistic.create!(:event => "Download", :ip_address => ip, :identifier => pid, :at_time => datetime)
        end
      end

    end

    puts count
  end
end
