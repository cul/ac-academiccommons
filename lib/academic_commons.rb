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
end
