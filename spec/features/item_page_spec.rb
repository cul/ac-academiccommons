require 'rails_helper'

describe 'Item Page', type: :feature do
  describe 'metadata tags' do
    before do
      visit solr_document_path('actest:1')
    end

    it 'renders open graph tags' do
      expect(page).to have_xpath('//head/meta[@property="og:site_name"][@content="Academic Commons"]', visible: false)
      expect(page).to have_xpath('//head/meta[@property="og:title"][@content="Alice\'s Adventures in Wonderland"]', visible: false)
      expect(page).to have_xpath('//head/meta[@property="og:url"][@content="https://doi.org/10.7916/ALICE"]', visible: false)
      expect(page).to have_xpath('//head/meta[@property="og:description"][@content="Background -  Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations."]', visible: false)
    end

    it 'renders twitter card tag' do
      within('head', visible: false) do
        expect(page).to have_xpath('//head/meta[@name="twitter:card"][@content="summary"]', visible: false)
      end
    end

    it 'renders required highwire tags' do
      expect(page).to have_xpath('//head/meta[@name="citation_title"][@content="Alice\'s Adventures in Wonderland"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_author"][@content="Carroll, Lewis"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_publication_date"][@content="1865"]', visible: false)
    end

    it 'renders additional highwire tags' do
      expect(page).to have_xpath('//head/meta[@name="citation_keywords"][@content="Tea Parties"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_abstract_html_url"][@content="http://www.example.com/solr_document/actest:1"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_pdf_url"][@content="http://www.example.com/download/fedora_content/download/actest:2/CONTENT/alice_in_wonderland.pdf"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_pdf_url"][@content="http://www.example.com/download/fedora_content/download/actest:4/content/to_solr.json"]', visible: false)
    end
  end
end
