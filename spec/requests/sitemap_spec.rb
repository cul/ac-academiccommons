require 'rails_helper'

describe 'Sitemap', type: :request do
  let(:current_time) { Time.current }

  let(:solr_doc) do
    SolrDocument.new(
      'id' => '10.7616/TEST', 'record_creation_dtsi' => current_time.utc.iso8601
    )
  end

  let(:expected_xml) do
    <<~HEREDOC
      <?xml version="1.0" encoding="utf-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.example.com/doi/10.7616/TEST</loc>
          <lastmod>#{current_time.utc.iso8601}</lastmod>
          <changefreq>yearly</changefreq>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC
  end

  # rubocop:disable RSpec/AnyInstance
  before do
    solr = instance_double('Solr')
    solr_response = instance_double('SolrResponse', docs: [solr_doc])
    allow_any_instance_of(Blacklight::SearchHelper).to receive(:repository).and_return(solr)
    allow(solr).to receive(:search).with(any_args).and_return(solr_response)
  end
  # rubocop:enable RSpec/AnyInstance

  it 'returns fresh results if it is stale' do
    get '/sitemap.xml'
    expect(response.status).to be 200
  end

  it 'returns a not modified response if not stale' do
    get '/sitemap.xml', headers: { 'If-Modified-Since' => current_time.httpdate }
    expect(response.status).to be 304
  end

  it 'returns expected body' do
    get '/sitemap.xml'
    expect(Nokogiri::XML(response.body)).to be_equivalent_to(expected_xml)
  end
end
