require 'rails_helper'

describe 'Item Page', type: :feature do
  before do
    visit solr_document_path('10.7916/ALICE')
  end

  it 'has the fixture object' do
    expect(page).to have_content('Weird Old Guys')
  end

  it 'has publication date' do
    expect(page).to have_xpath('//span[@itemprop=\'datePublished\']', text: '1865')
  end

  it 'has title' do
    expect(page).to have_css('h1', text: 'Alice\'s Adventures in Wonderland')
  end

  it 'has abstract' do
    expect(page).to have_content('Background - Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations.')
  end

  # it 'displays abstract with paragraph breaks' do
  #   expect(page).to have_html # to have an abstract with a p break <br>
  # end

  it 'has volume' do
    expect(page).to have_xpath('//dt[contains(text(),\'Volume\')]/following-sibling::dd', text: '1')
  end

  it 'has doi' do
    expect(page).to have_content('10.7916/ALICE')
  end

  it 'has journal title' do
    expect(page).to have_xpath('//dt[contains(text(),\'Published In\')]/following-sibling::dd', text: 'Project Gutenberg')
  end

  it 'has linked url' do
    expect(page).to have_link 'https://www.gutenberg.org/ebooks/28885'
  end

  it 'has linked subject' do
    expect(page).to have_xpath('//a[@href=\'/search?f%5Bsubject_ssim%5D%5B%5D=Tea+Parties\']', text: 'Tea Parties')
  end

  it 'has linked publisher doi' do
    expect(page).to have_xpath('//a[@href=\'https://doi.org/10.1378/wonderland.01-2345\']', text: 'https://doi.org/10.1378/wonderland.01-2345')
  end

  xit 'links to the MODS download' do # TODO: Only for administrators
    expect(page).to have_css('a[href="/download/fedora_content/show_pretty/actest:1/descMetadata/actest1_description.xml?data=meta"]', text: 'text')
    page.find('a[href="/download/fedora_content/show_pretty/actest:1/descMetadata/actest1_description.xml?data=meta"]', text: 'text').click
    expect(page).to have_text('Alice\'s Adventures in Wonderland')
  end

  it 'has license/rights information' do
    expect(page).to have_link 'All Rights Reserved', href: 'http://rightsstatements.org/vocab/InC/1.0/'
    expect(page).to have_css 'img[src*="in-copyright"][alt="In Copyright"]'
  end

  it 'links to asset downloads' do
    expect(page).to have_xpath '//a[@href=\'/doi/10.7916/TESTDOC2/download\']'
    expect(page).to have_xpath '//a[@href=\'/doi/10.7916/TESTDOC4/download\']'
  end

  it 'has correct itemtype' do
    expect(page).to have_xpath('//div[@itemtype="http://schema.org/ScholarlyArticle"]', visible: false)
  end

  describe 'download links for' do
    xit 'download links return X-Accel-Redirect header' do
      click_on 'alice_in_wonderland.pdf'
      expect(page.response_headers['X-Accel-Redirect']).to match %r{\/repository_download\/.*\/actest:2\/datastreams\/CONTENT\/content$/}
    end
  end

  describe 'metadata tags' do
    it 'renders open graph tags' do
      expect(page).to have_xpath('//head/meta[@property="og:site_name"][@content="Academic Commons"]', visible: false)
      expect(page).to have_xpath('//head/meta[@property="og:title"][@content="Alice\'s Adventures in Wonderland"]', visible: false)
      expect(page).to have_xpath('//head/meta[@property="og:url"][@content="https://doi.org/10.7916/ALICE"]', visible: false)
      expect(page).to have_xpath('//head/meta[@property="og:description"][@content="Background -  Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations."]', visible: false)
    end

    it 'renders twitter card tag' do
      within('head', visible: false) do
        expect(page).to have_xpath('//head/meta[@name="twitter:card"][@content="summary_large_image"]', visible: false)
      end
    end

    it 'renders required highwire tags' do
      expect(page).to have_xpath('//head/meta[@name="citation_title"][@content="Alice\'s Adventures in Wonderland"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_author"][@content="Carroll, Lewis"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_publication_date"][@content="1865"]', visible: false)
    end

    it 'renders additional highwire tags' do
      expect(page).to have_xpath('//head/meta[@name="citation_keywords"][@content="Tea Parties"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_pdf_url"][@content="http://www.example.com/doi/10.7916/TESTDOC2/download"]', visible: false)
      expect(page).to have_xpath('//head/meta[@name="citation_pdf_url"][@content="http://www.example.com/doi/10.7916/TESTDOC4/download"]', visible: false)
    end
  end
end
