module OkComputer
  class FedoraCheck < HttpCheck
    def initialize(request_timeout = 5)
      url = "#{ActiveFedora.config.credentials[:url]}/describe"
      super(url, request_timeout)
    end
  end
end
