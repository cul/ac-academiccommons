require 'rails_helper'

RSpec.describe 'static pages', type: :feature do
  context 'about' do
    before do
      visit 'about'
    end

    it 'render about page' do
      expect(page).to have_content 'Columbia University Libraries'
      expect(page).to have_content 'About'
    end

    it 'has link to API documentation' do
      expect(page).to have_link 'Academic Commons API', href: developers_path(anchor: 'api')
    end
  end

  context 'credits' do
    it 'render credits page' do
      visit 'credits'
      expect(page).to have_content 'Credits'
      expect(page).to have_content 'Core team'
    end
  end

  context 'developers' do
    before do
      visit 'developers'
    end

    it 'render developer resources page' do
      expect(page).to have_content 'Developer Resources'
      expect(page).to have_css '#api'
      expect(page).to have_css '#oai'
      expect(page).to have_css '#sword'
    end

    it 'includes the metadata license' do
      expect(page).to have_link href: 'https://creativecommons.org/publicdomain/zero/1.0/'
    end
  end

  context 'faq' do
    it 'render faq page' do
      visit 'faq'
      expect(page).to have_content 'Frequently Asked Questions'
      expect(page).to have_content 'How do I contact repository staff?'
      expect(page).to have_css '#policies'
    end
  end

  context 'policies' do
    before do
      visit 'policies'
    end

    it 'render policies page' do
      expect(page).to have_content 'Policies'
      expect(page).to have_content 'Terms of Use'
    end

    it 'has link to University Confidentiality of Library Records Policy' do
      expect(page).to have_link href: 'http://library.columbia.edu/about/policies/confidentiality.html'
    end

    it 'has link to Columbia University Data breach Reporting and Responsibility Policy' do
      expect(page).to have_link href: 'https://universitypolicies.columbia.edu/content/electronic-data-security-breach-reporting-and-response-policy' # rubocop:disable Layout/LineLength
    end
  end
end
