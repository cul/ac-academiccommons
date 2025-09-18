module FixtureHelpers
  def fixture(*path)
    File.join(fixture_paths, *path)
  end

  def fixture_to_str(*path)
    File.read(fixture(path))
  end

  def fixture_to_json(*path)
    JSON.parse(fixture_to_str(*path))
  end

  def fixture_to_xml(*path)
    Nokogiri::XML(fixture_to_str(*path))
  end
end
