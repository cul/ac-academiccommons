require 'rails_helper'

describe 'Search Results Page', type: :feature do
  xit 'finds by title' do
    visit search_catalog_path(q: 'alice')
    expect(page).to have_css('a[href="/catalog/actest:1"]', text: 'Alice\'s Adventures in Wonderland')
  end

  xit 'finds by author' do
    visit search_catalog_path(q: 'lewis carroll')
    expect(page).to have_content('Carroll, Lewis')
    expect(page).to have_css('a[href="/catalog/actest:1"]', text: 'Alice\'s Adventures in Wonderland')
  end

  xit 'returns nothing when search query is not a match' do
    visit search_catalog_path(q: 'nothing')
    expect(page).to have_content('No items found')
  end

  xit 'indicates active search in the form widget' do
    visit search_catalog_path(q: 'alice')
    select('year', from: 'sort')
    click_on('sort results')
    expect(page).to have_select('sort', selected: 'year')
  end

  context 'expects query results page to' do
    before do
      visit search_catalog_path(q: 'alice')
    end

    xit 'have facets for subjects' do
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Bildungsromans')
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Nonsense literature')
    end

    xit 'have facets for authors' do
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Carroll, Lewis')
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Weird Old Guys.')
    end

    xit 'have facets for departments' do
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Bucolic Literary Society.')
    end

    xit 'have facets for language' do
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'English')
    end

    xit 'have facets for date' do
      expect(page).to have_css('span.facet-label > a.facet_select', text: '1865')
    end

    xit 'have facets for content type' do
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Articles')
    end

    xit '\'more\' link for subject facets is present' do
      expect(page).to have_css('ul.facet-values > li.more_facets_link > a', text: 'more ')
    end

    context 'clicking on \'more\' link', js: true do
      before do
        click_link 'more '
      end

      xit 'opens dialog box with correct title' do
        expect(page).to have_css('span.ui-dialog-title', text: 'Subject')
      end

      xit 'shows all three facets' do
        expect(page).to have_css('ul.facet_extended_list > li > span > a.facet_select', text: 'Nonsense literature')
        expect(page).to have_css('ul.facet_extended_list > li > span > a.facet_select', text: 'Rabbits')
        expect(page).to have_css('ul.facet_extended_list > li > span > a.facet_select', text: 'Rabbits')
        expect(page).to have_css('ul.facet_extended_list > li > span > a.facet_select', text: 'Tea Parties')
        expect(page).to have_css('ul.facet_extended_list > li > span > a.facet_select', text: 'Wonderland')
      end
    end
  end
end
