require 'rails_helper'

describe 'Homepage', type: :feature do
  shared_context 'when visiting the home page' do
    before do
      visit root_path
    end
  end

  describe 'when visiting home page' do
    include_context 'when visiting the home page'

    it 'has the "Stats at a glance" content panel' do
      expect(page).to have_content('Stats at a glance')
    end

    it 'renders the CUL header' do
      expect(page).to have_css('div.cul-banner', text: 'Columbia University Libraries')
    end

    it 'links to the about page' do
      within('.about-links') do
        expect(page).to have_link('About', href: '/about')
        click_link 'About'
      end
      expect(page).to have_css 'h3', text: 'Enhanced discoverability'
    end

    it 'links to the explore page' do
      within('.about-links') do
        expect(page).to have_link('Explore', href: '/explore')
      end
    end

    it 'displays correct total number of items in repository' do
      expect(page).to have_content('1 total works')
    end
  end

  describe 'when rendering the home page with site options' do
    context 'when deposits are enabled' do
      # Deposits are enabled by default by SiteConfiguration model

      include_context 'when visiting the home page'
      it 'links to the upload page' do
        expect(page).to have_css('a[href="/upload"]')
      end
    end

    context 'when deposits are disabled' do
      before do
        SiteConfiguration.instance.update(deposits_enabled: false)
      end

      include_context 'when visiting the home page'
      it 'does not link to the upload page' do
        expect(page).not_to have_css('a[href="/upload"]')
      end
    end
  end
end
