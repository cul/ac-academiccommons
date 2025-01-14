require 'rails_helper'

describe 'rake sitemap:create', type: :task do
  let(:path) { Rails.root.join('public', 'sitemaps', 'sitemap.xml.gz') }
  let(:expected_xml) { fixture_to_xml('sitemap', 'urlset.xml') }

  before { task.execute }

  after {  File.delete(path) if File.exist?(path) }

  it 'generates sitemap with out errors' do
    expect(File.exist?(path)).to be true
  end

  it 'returns expected body' do
    gz = Zlib::GzipReader.open(path)
    actual_xml = gz.read
    gz.close

    expect(actual_xml).to be_equivalent_to(expected_xml).ignoring_content_of('urlset > url > lastmod')
  end
end
