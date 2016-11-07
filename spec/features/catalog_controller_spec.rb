require 'rails_helper'

describe CatalogController, :type => :feature do

  describe "index" do
    context "homepage" do # when there isn't a search query it displays the homepage
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

      it "has the new content panel" do
        expect(page).to have_content("New in Academic Commons")
      end

      it "displays recently added item" do
        expect(page).to have_content("Alice's Adventures in Wonderland")
      end

      it "displays correct number of items in repository" do
        expect(page).to have_content("1 items in Academic Commons")
      end
    end

    context "search query" do
      it "finds by title" do
        visit catalog_index_path(q: "alice")
        expect(page).to have_css("a[href=\"/catalog/actest:1\"]", :text => "Alice's Adventures in Wonderland")
      end

      it "finds by author" do
        visit catalog_index_path(q: "lewis carroll")
        expect(page).to have_content("Carroll, Lewis")
        expect(page).to have_css("a[href=\"/catalog/actest:1\"]", :text => "Alice's Adventures in Wonderland")
      end

      it "returns nothing when search query is not a match" do
        visit catalog_index_path(q: "nothing")
        expect(page).to have_content("No items found")
      end

      context "expects query results page to" do
        before do
          visit catalog_index_path(q: "alice")
        end

        it "have facets for subjects" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Tea Parties")
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Rabbits")
        end

        it "have facets for authors" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Carroll, Lewis")
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Weird Old Guys.")
        end

        it "have facets for departments" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Bucolic Literary Society.")
        end

        it "have facets for language" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "English")
      end

        it "have facets for date" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "1865")
        end

        it "have facets for content type" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Articles")
        end
      end
    end
  end

  describe "show" do
    before do
      visit catalog_path("actest:1")
    end

    it "has the fixture object" do
      expect(page).to have_content("Weird Old Guys")
    end

    it "has publication date" do
      expect(page).to have_xpath("//dd[@itemprop='datePublished']", :text => "1865")
    end

    it "has title" do
      expect(page).to have_css(".document_title", :text => "Alice's Adventures in Wonderland")
    end

    it "has abstract" do
      expect(page).to have_xpath("//dd[@itemprop='description']", :text => "Background - Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations.")
    end

    it "has volume" do
      expect(page).to have_xpath("//dt[contains(text(),'Volume:')]/following-sibling::dd", :text => "7")
    end

    it "has doi" do
      expect(page).to have_xpath("//dt[contains(text(),'Publisher DOI:')]/following-sibling::dd", :text => "10.1378/wonderland.01-2345")
    end

    it "has journal title" do
      expect(page).to have_xpath("//dt[contains(text(),'Book/Journal Title:')]/following-sibling::dd", :text => "Project Gutenberg")
    end

    it "has item views" do
      expect(page).to have_xpath("//dt[contains(text(),'Item views')]/following-sibling::dd", :text => "0")
    end

    it "links to the MODS download" do
      expect(page).to have_css("a[href=\"/download/fedora_content/show_pretty/actest:3/CONTENT/actest3_description.xml?data=meta\"]", :text => "text")
    end

    it "links to the pdf download" do
      click_on 'alice_in_wonderland.pdf'
      expect(page.response_headers['X-Accel-Redirect']).to match /\/repository_download\/.*\/actest:2\/CONTENT$/
    end
  end

  describe "department browse" do
    before { visit departments_browse_path }
    let(:authors) { "Weird Old Guys" }
    let(:department) { "Bucolic Literary Society" }

    it "has indexed departments listed" do
      expect(page).to have_content(department)
      click_on department
      expect(page).to have_link(authors)
    end
  end

  describe "subjects browse" do
    before do
      visit subjects_browse_path
    end

    it "lists two subjects" do
      expect(page).to have_content("Tea Parties")
      expect(page).to have_content("Wonderland")
    end

    it "subjects link to page with results" do
      click_on "Tea Parties"
      expect(page).to have_content "Alice's Adventures in Wonderland"
    end
  end

  describe "browse" do
    before do
      visit '/catalog/browse'
    end

    it 'redirects to subject browse' do
      expect(current_path).to eq '/catalog/browse/subjects'
    end
  end
end
