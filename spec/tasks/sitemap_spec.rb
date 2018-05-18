require 'rails_helper'

describe 'rake sitemap:create', type: :task do
  let(:path) { Rails.root.join('public', 'sitemap.xml.gz') }
  let(:expected_xml) do
    '<?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
            xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
            xmlns:video="http://www.google.com/schemas/sitemap-video/1.1" xmlns:news="http://www.google.com/schemas/sitemap-news/0.9"
            xmlns:mobile="http://www.google.com/schemas/sitemap-mobile/1.0" xmlns:pagemap="http://www.google.com/schemas/sitemap-pagemap/1.0" xmlns:xhtml="http://www.w3.org/1999/xhtml">
      <url>
        <loc>http://localhost:3000</loc>
        <lastmod>2018-05-18T10:57:43-04:00</lastmod>
        <changefreq>always</changefreq>
        <priority>1.0</priority>
      </url>
      <url>
        <loc>http://localhost:3000/about</loc>
        <lastmod>2018-05-18T10:57:43-04:00</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.7</priority>
      </url>
      <url>
        <loc>http://localhost:3000/policies</loc>
        <lastmod>2018-05-18T10:57:43-04:00</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.7</priority>
      </url>
      <url>
        <loc>http://localhost:3000/faq</loc>
        <lastmod>2018-05-18T10:57:43-04:00</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.7</priority>
      </url>
      <url>
        <loc>http://localhost:3000/developers</loc>
        <lastmod>2018-05-18T10:57:43-04:00</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.7</priority>
      </url>
      <url>
        <loc>http://localhost:3000/doi/10.7916/ALICE</loc>
        <lastmod>2017-09-14T16:48:05Z</lastmod>
        <changefreq>yearly</changefreq>
        <priority>0.5</priority>
      </url>
    </urlset>'
  end

  before { task.execute }

  it 'generates sitemap with out errors' do
    expect(File.exist?(path)).to be true
  end

  it 'returns expected body' do
    gz = Zlib::GzipReader.open(path)
    actual_xml = gz.read
    gz.close

    expect(actual_xml).to be_equivalent_to(Nokogiri::XML(expected_xml)).ignoring_content_of('urlset > url > lastmod')
  end
end
