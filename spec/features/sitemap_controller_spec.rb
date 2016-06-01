require 'spec_helper'

describe SitemapController, :type => :controller do
  render_views
  before do
    @lmd = Time.now.httpdate # rfc2822
    solr_doc = {'id' => 'example_id', 'record_creation_date' => @lmd}
    solr = double('Solr')
    solr_response = double('SolrResponse')
    allow(Blacklight).to receive(:solr).and_return(solr)
    allow(solr_response).to receive(:docs).and_return([solr_doc])
    expect(solr).to receive(:find).and_return(solr_response)
  end

  it "should return fresh results if it is stale" do
    visit '/sitemap.xml'
    expect(page.status_code).to eql(200)
    expect(page).to have_selector('urlset')
  end

  it "should return a not modified response if not stale" do
    request.env['HTTP_IF_MODIFIED_SINCE'] = @lmd
    Capybara.current_session.driver.header 'If-Modified-Since', @lmd
    Capybara.current_session.visit '/sitemap.xml'
    expect(page.status_code).to eql(304)
  end

end