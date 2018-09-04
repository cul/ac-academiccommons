require 'rails_helper'

describe 'Search Results Page', type: :feature do
  it 'finds by title' do
    visit search_catalog_path(q: 'alice')
    expect(page).to have_css('a[href="/doi/10.7916/ALICE"]', text: 'Alice\'s Adventures in Wonderland')
  end

  it 'finds by author' do
    visit search_catalog_path(q: 'lewis carroll')
    expect(page).to have_content('Carroll, Lewis')
    expect(page).to have_css('a[href="/doi/10.7916/ALICE"]', text: 'Alice\'s Adventures in Wonderland')
  end

  it 'returns nothing when search query is not a match' do
    visit search_catalog_path(q: 'nothing')
    expect(page).to have_content('No entries found')
  end

  it 'indicates active search in the form widget' do
    visit search_catalog_path(q: 'alice')
    click_button 'Sort by Best Match'
    click_link 'Published Earliest'
    expect(page).to have_button 'Sort by Published Earliest'
  end

  context 'when admin logged in' do
    include_context 'admin user for feature'

    before do
      visit search_catalog_path(q: 'alice')
    end

    it 'displays resource type facet' do
      expect(page).to have_content 'Resource Type'
    end
  end

  context 'expects query results page to' do
    before do
      visit search_catalog_path(q: 'alice')
    end

    it 'have facets for subjects' do
      click_link 'Subject'
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Bildungsromans')
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Nonsense literature')
    end

    it 'have facets for authors' do
      click_link 'Author'
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Carroll, Lewis')
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Weird Old Guys.')
    end

    it 'have facets for academic unit' do
      click_link 'Academic Unit'
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Bucolic Literary Society.')
    end

    it 'have facets for language' do
      click_link 'Language'
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'English')
    end

    it 'have facets for date' do
      click_link 'Date Published'
      expect(page).to have_css('span.facet-label > a.facet_select', text: '1865')
    end

    it 'have facets for type' do
      click_link 'Type'
      expect(page).to have_css('span.facet-label > a.facet_select', text: 'Articles')
    end

    it 'does not have facet for resource type' do
      expect(page).not_to have_content('Resource Type')
    end

    it '\'more \' link for subject facets is present' do
      within('div.blacklight-subject_ssim') do
        click_link 'Subject'
        expect(page).to have_link 'more '
      end
    end

    context 'clicking on \'more \' link', js: true do
      before do
        within('div.blacklight-subject_ssim') do
          click_link 'Subject'
          click_link 'more '
        end
      end

      it 'opens dialog box with correct title' do
        within('#ajax-modal') do
          expect(page).to have_content 'Subject'
        end
      end

      it 'shows all six facets' do
        within('#ajax-modal') do
          ['Nonsense literature', 'Bildungsromans', 'Rabbits', 'Tea Parties', 'Wonderland', 'Magic'].each do |subject|
            expect(page).to have_link subject
          end
        end
      end
    end
  end
end
