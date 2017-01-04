class Statistic < ActiveRecord::Base
  VIEW_EVENT = 'View'
  DOWNLOAD_EVENT = 'Download'
  STREAM_EVENT = 'Streaming'

  EVENTS = [VIEW_EVENT, DOWNLOAD_EVENT, STREAM_EVENT]

  # Calculate the number of times the event given has occured for all the given
  # asset_pids.
  #
  # @param [Array<String>|String] asset_pids
  # @param String event
  def self.per_identifier(asset_pids, event)
    # Check parameters.
    asset_pids = [asset_pids] if asset_pids.is_a? String

    raise 'asset_pids must be an Array or String' unless asset_pids.is_a? Array
    raise "event must one of #{EVENTS}"           unless valid_event?(event)

    group(:identifier).where("identifier IN (?) and event = ?", asset_pids, event).count
  end

  def self.valid_event?(e)
    EVENTS.include?(e)
  end

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
