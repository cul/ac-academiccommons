module OkComputer
  class FedoraObjectCheck < HttpCheck
    attr_accessor :pid, :ds

    # Checking that fedora object exists.
    def initialize(pid = 'ac:151668', ds = 'DC', request_timeout = 5)
      self.pid = pid
      self.ds = ds
      self.url = create_url
      self.request_timeout = request_timeout.to_i
    end

    # Overriding this method to use a HEAD request instead of GET request.
    # Throws error if HEAD request not successful.
    def perform_request
      Timeout.timeout(request_timeout) do
        options = { use_ssl: url.scheme == 'https', read_timeout: request_timeout }
        Net::HTTP.start(url.host, url.port, options) { |r|
          r.head(url)
        }.value
      end
    rescue => e
      raise ConnectionFailed, e
    end

    def create_url
      fedora_url = ActiveFedora.config.credentials[:url]
      URI.parse("#{fedora_url}/objects/#{pid}/datastreams/#{ds}/content")
    end
  end
end
