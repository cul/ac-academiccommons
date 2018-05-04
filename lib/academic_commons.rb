module AcademicCommons
  # Converts handles or DOIs to full urls. If str does not match a DOI or
  # handle format, returns the string unchanged.
  def self.identifier_url(str)
    case str
    when /^(AC:P:\d+)$/
      "http://hdl.handle.net/10022/#{$1}"
    when /^(10.+)$/
      "https://doi.org/#{$1}"
    else
      str
    end
  end

  # Returns solr search response. User must provide a block which changes the
  # SearchParameters object. This method uses Blacklight to conduct a search with
  # our own parameters. Use this method when retriving records outside of the
  # typical blacklight controller context. This way, there's a centralized place
  # to make those request.
  #
  # @example
  #  solr_response = AcademicCommons.search do |parameters|
  #   parameters.rows(1)
  #   parameters.aggregators_only
  #   parameters.filter('fedora3_pid_ssi', 'actest:1')
  # end
  #
  # @return [Blacklight::Solr::Response] response object
  def self.search
    params = SearchParameters.new
    yield(params)
    Blacklight.default_index.search(params.to_h)
  end
end
