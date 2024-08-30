require 'rails_helper'

describe 'Homepage', type: :feature do
  before { visit root_path }

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

  context 'when deposits are enabled' do
    before do 
      SiteOption.create!(name: 'deposits_enabled', value: true)
      visit root_path 
    end
    it 'links to the upload page' do
      expect(page).to have_css('a[href="/upload"]')
    end
  end

  context 'when deposits are disabled' do
    before do 
      SiteOption.create!(name: 'deposits_enabled', value: false)
      visit root_path 
    end
    it 'does not link to the upload page' do
      expect(page).not_to have_css('a[href="/upload"]')
    end
  end
end
