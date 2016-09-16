require 'spec_helper'

describe CatalogController, :type => [:controller,:feature] do

  render_views

  describe "index" do
    before do
      visit root_path
    end
    it "has the new content panel" do
      expect(page).to have_content("New in Academic Commons")
    end
    it "renders the CUL header" do
      # this needs to look for an included script
      # have_content|css|xpath are for visible content only, have_selector with options can find script tags
      opts = {:visible => false, :count => 1}
      expect(page).to have_selector(:css, "script[src=\"//cdn.cul.columbia.edu/ldpd-toolkit/widgets/cultnbw.min.js\"]", opts)
    end
    it "links to the about page" do
      # this needs to look for a link by href
      expect(page).to have_css("a[href=\"/about/\"]")
      # if we click on the link, the next page should have expected content
      click_on 'About Academic Commons'
      expect(page).to have_css "div#subhead_1", :text => "Deposit Your Research and Scholarship"
    end
    it "links to the self-deposit page" do
      # this needs to look for a link by href
      expect(page).to have_css("a[href=\"/deposit\"]")
    end
  end
  describe "show" do
    before do
      visit catalog_path("actest:1")
    end
    it "has the fixture object" do
      expect(page).to have_content("Weird Old Guys")
    end
    it "links to the pdf download" do
      click_on 'alice_in_wonderland.pdf'
      expect(page.response_headers['X-Accel-Redirect']).to match /\/repository_download\/.*\/actest:2\/CONTENT$/
    end
  end
end