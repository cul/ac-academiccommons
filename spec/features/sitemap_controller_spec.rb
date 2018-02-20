require 'rails_helper'

describe SitemapController, type: :feature do
  before do
    @lmd = Time.now.httpdate # rfc2822
    solr_doc = { 'id' => 'example_id', 'record_creation_date' => @lmd }
    solr = double('Solr')
    solr_response = double('SolrResponse')
    allow(Blacklight).to receive(:default_index).and_return(solr)
    allow(solr_response).to receive(:docs).and_return([solr_doc])
    allow(solr).to receive(:find).and_return(solr_response)
  end

  it 'should return fresh results if it is stale' do
    visit '/sitemap.xml'
    expect(page.status_code).to be 200
    expect(page).to have_selector('urlset')
  end

  it 'should return a not modified response if not stale' do
    Capybara.current_session.driver.header 'If-Modified-Since', @lmd
    Capybara.current_session.visit '/sitemap.xml'
    expect(page.status_code).to be 304
  end
end
