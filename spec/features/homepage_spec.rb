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

  it 'links to the upload page' do
    # this needs to look for a link by href
    expect(page).to have_css('a[href="/upload"]')
  end

  it 'displays correct total number of items in repository' do
    expect(page).to have_content('1 total works')
  end
end
