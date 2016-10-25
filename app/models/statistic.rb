class Statistic < ActiveRecord::Base
  VIEW_EVENT = 'View'
  DOWNLOAD_EVENT = 'Download'
  STREAM_EVENT = 'Streaming'

  def self.reset_downloads
    Statistic.where(:event => "Download").each { |e| e.delete }

    fedora_download_match = /^([\d\.]+).+\[([^\]]+)\].+download\/fedora_content\/\w+\/([^\/]+)/
    startdate = DateTime.parse("5/1/2011")

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
  end
end
