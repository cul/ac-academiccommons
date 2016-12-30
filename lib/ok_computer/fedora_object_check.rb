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
        options = { use_ssl: self.url.scheme == 'https', read_timeout: request_timeout }
        Net::HTTP.start(self.url.host, self.url.port, options) { |r|
          r.head(self.url)
        }.value
      end
    rescue => e
      raise ConnectionFailed, e
    end

    def create_url
      fedora_url = ActiveFedora.config.credentials[:url]
      URI.parse("#{fedora_url}/objects/#{self.pid}/datastreams/#{self.ds}/content")
    end
  end
end
