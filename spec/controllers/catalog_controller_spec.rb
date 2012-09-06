require 'spec_helper'

describe "sitemap.xml behavior" do

    it "should return fresh results if it is stale" do
      # visit '/catalog/sitemap.xml'
       #to do: make it so that the request will elicit stale
       page.should have_selector('urlset')
    end

    it "should return a not modified response if not stale" do
       #visit '/catalog/sitemap.xml'
       #to do: make it so that the request will elicit fresh
      response.status.should be(304)
     end

end