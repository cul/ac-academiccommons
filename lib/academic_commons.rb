module AcademicCommons
  # Returns app version number
  def self.version
    IO.read(Rails.root.join('VERSION')).strip
  end

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

  # Returns list of all author unis (removes any duplicates).
  #
  # @return [String]
  def self.all_author_unis
    AcademicCommons.search { |i| i.field_list('author_uni_ssim') }
                   .docs.map { |f| f['author_uni_ssim'] }
                   .flatten.compact.uniq
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
    solr_path = params.solr_path
    # in Blacklight >= 8.4, the search method accepts a path kwarg; in 7, we have to call send_and_receive
    # this unrolls the call to search for BL 7 and uses our solr_path if present
    if solr_path
      Blacklight.default_index.blacklight_config.http_method = :post
      Blacklight.default_index.send_and_receive(solr_path, params.to_h)
    else
      Blacklight.default_index.search(params.to_h)
    end
  end
end
