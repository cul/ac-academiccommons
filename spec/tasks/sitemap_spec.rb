require 'rails_helper'

describe 'rake sitemap:create', type: :task do
  let(:path) { Rails.root.join('public', 'sitemap.xml.gz') }
  let(:expected_xml) do
    <<~HEREDOC
      <?xml version="1.0" encoding="utf-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.example.com/doi/10.7616/TEST</loc>
          <lastmod>need to get actual time</lastmod>
          <changefreq>yearly</changefreq>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC
  end
  let(:actual_xml) { '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"></urlset>' }

  before { task.execute }

  it 'generates sitemap with out errors' do
    expect(File.exist?(path)).to be true
  end

  it 'returns expected body' do
    pending 'needs to be implemented'
    get '/sitemap.xml'
    expect(actual_xml).to be_equivalent_to(expected_xml)
  end
end
