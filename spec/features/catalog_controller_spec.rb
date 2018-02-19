require 'rails_helper'

describe CatalogController, :type => :feature do

  describe "index" do
    context "homepage" do # when there isn't a search query it displays the homepage
      before do
        visit root_path
      end

      xit "has the new content panel" do
        expect(page).to have_content("New in Academic Commons")
      end

      xit "renders the CUL header" do
        # this needs to look for an included script
        # have_content|css|xpath are for visible content only, have_selector with options can find script tags
        opts = {:visible => false, :count => 1}
        expect(page).to have_selector(:css, "script[src=\"//cdn.cul.columbia.edu/ldpd-toolkit/widgets/cultnbw.min.js\"]", opts)
      end

      xit "links to the about page" do
        # this needs to look for a link by href
        expect(page).to have_css("a[href=\"/about/\"]")
        # if we click on the link, the next page should have expected content
        click_on 'About Academic Commons'
        expect(page).to have_css "h2", text: "Deposit Your Research and Scholarship"
      end

      xit "links to the self-deposit page" do
        # this needs to look for a link by href
        expect(page).to have_css("a[href=\"/deposit\"]")
      end

      xit "has the new content panel" do
        expect(page).to have_content("New in Academic Commons")
      end

      xit "displays recently added item" do
        expect(page).to have_content("Alice's Adventures in Wonderland")
      end

      xit "displays correct total number of items in repository" do
        expect(page).to have_content("1 items in Academic Commons")
      end

      xit "displays correct yearly number of items in repository" do
        expect(page).to have_content("Objects added in the last year: 1")
      end

      xit "displays correct monthly number of items in repository" do
        expect(page).to have_content("Objects added in the last 30 days: 0")
      end
    end

    context "search query" do
      xit "finds by title" do
        visit search_catalog_path(q: "alice")
        expect(page).to have_css("a[href=\"/catalog/actest:1\"]", :text => "Alice's Adventures in Wonderland")
      end

      xit "finds by author" do
        visit search_catalog_path(q: "lewis carroll")
        expect(page).to have_content("Carroll, Lewis")
        expect(page).to have_css("a[href=\"/catalog/actest:1\"]", :text => "Alice's Adventures in Wonderland")
      end

      xit "returns nothing when search query is not a match" do
        visit search_catalog_path(q: "nothing")
        expect(page).to have_content("No items found")
      end

      xit "indicates active search in the form widget" do
        visit search_catalog_path(q: "alice")
        select("year", from: "sort")
        click_on("sort results")
        expect(page).to have_select("sort", selected: "year")
      end

      context "expects query results page to" do
        before do
          visit search_catalog_path(q: "alice")
        end

        xit "have facets for subjects" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Bildungsromans")
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Nonsense literature")
        end

        xit "have facets for authors" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Carroll, Lewis")
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Weird Old Guys.")
        end

        xit "have facets for departments" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Bucolic Literary Society.")
        end

        xit "have facets for language" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "English")
        end

        xit "have facets for date" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "1865")
        end

        xit "have facets for content type" do
          expect(page).to have_css("span.facet-label > a.facet_select", text: "Articles")
        end

        context "'more' link for subject facets" do
          xit "is present" do
            expect(page).to have_css("ul.facet-values > li.more_facets_link > a", text: 'more ')
          end

          context "clicking on link", :js => true do
            before do
              click_link "more "
            end

            xit "opens dialog box with correct title" do
              expect(page).to have_css("span.ui-dialog-title", text: "Subject")
            end

            xit "shows all three facets" do
              expect(page).to have_css("ul.facet_extended_list > li > span > a.facet_select", text: "Nonsense literature")
              expect(page).to have_css("ul.facet_extended_list > li > span > a.facet_select", text: "Rabbits")
              expect(page).to have_css("ul.facet_extended_list > li > span > a.facet_select", text: "Rabbits")
              expect(page).to have_css("ul.facet_extended_list > li > span > a.facet_select", text: "Tea Parties")
              expect(page).to have_css("ul.facet_extended_list > li > span > a.facet_select", text: "Wonderland")
            end
          end
        end
      end
    end
  end

  describe "show" do
    before do
      visit catalog_path("actest:1")
    end

    xit "has the fixture object" do
      expect(page).to have_content("Weird Old Guys")
    end

    xit "has publication date" do
      expect(page).to have_xpath("//dd/span[@itemprop='datePublished']", :text => "1865")
    end

    xit "has title" do
      expect(page).to have_css("div.document-heading/h1", :text => "Alice's Adventures in Wonderland")
    end

    xit "has abstract" do
      expect(page).to have_xpath("//dd/span[@itemprop='description']", text: "Background - Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations.")
    end

    xit "has volume" do
      expect(page).to have_xpath("//dt[contains(text(),'Volume:')]/following-sibling::dd", text: "7")
    end

    xit "has linked persistent url" do
      expect(page).to have_xpath("//a[@href='https://doi.org/10.7916/ALICE']", text: 'https://doi.org/10.7916/ALICE')
    end

    xit "has doi" do
      expect(page).to have_xpath("//dt[contains(text(),'Publisher DOI:')]/following-sibling::dd", text: "10.1378/wonderland.01-2345")
    end

    xit "has journal title" do
      expect(page).to have_xpath("//dt[contains(text(),'Book/Journal Title:')]/following-sibling::dd", text: "Project Gutenberg")
    end

    xit "has linked subject" do
      expect(page).to have_xpath("//a[@href='/?f%5Bsubject_facet%5D%5B%5D=Tea+Parties']", text: 'Tea Parties')
    end

    xit "has item views" do
      expect(page).to have_xpath("//dt[contains(text(),'Item views')]/following-sibling::dd", text: "0")
    end

    xit "has linked publisher doi" do
      expect(page).to have_xpath("//a[@href='https://doi.org/10.1378/wonderland.01-2345']", text: 'https://doi.org/10.1378/wonderland.01-2345')
    end

    xit "has suggested citation" do
      expect(page).to have_xpath("//dt[contains(text(),'Suggested Citation')]/following-sibling::dd",
        text: 'Lewis Carroll, Weird Old Guys., 1865, Alice\'s Adventures in Wonderland, Columbia University Academic Commons, https://doi.org/10.7916/ALICE.')
    end

    xit "links to the MODS download" do
      expect(page).to have_css("a[href=\"/download/fedora_content/show_pretty/actest:1/descMetadata/actest1_description.xml?data=meta\"]", :text => "text")
      page.find("a[href=\"/download/fedora_content/show_pretty/actest:1/descMetadata/actest1_description.xml?data=meta\"]", text: "text").click
      expect(page).to have_text("Alice's Adventures in Wonderland")
    end

    xit "links to the pdf download" do
      click_on 'alice_in_wonderland.pdf'
      expect(page.response_headers['X-Accel-Redirect']).to match /\/repository_download\/.*\/actest:2\/datastreams\/CONTENT\/content$/
    end

    xit "links to the non-pdf download" do
      click_on 'to_solr.json'
      expect(page.response_headers['X-Accel-Redirect']).to match /\/repository_download\/.*\/actest:4\/datastreams\/content\/content$/
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

    xit "lists two subjects" do
      expect(page).to have_content("Tea Parties")
      expect(page).to have_content("Wonderland")
    end

    xit "subjects link to page with results" do
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
