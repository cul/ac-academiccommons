require 'rails_helper'

describe 'Search Results Page', type: :feature do
  let(:mock_vector_embedding_value) do
    fixture_to_json('desc_metadata/mock_vector_embedding_value_string-research.json')
  end

  before do
    allow(EmbeddingService::Endpoint).to receive(:generate_vector_embedding).and_return(mock_vector_embedding_value)
  end

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
      click_button 'Subject'
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'Bildungsromans')
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'Nonsense literature')
    end

    it 'have facets for authors' do
      click_button 'Author'
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'Carroll, Lewis')
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'Weird Old Guys.')
    end

    it 'have facets for academic unit' do
      click_button 'Academic Unit'
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'Bucolic Literary Society.')
    end

    it 'have facets for language' do
      click_button 'Language'
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'English')
    end

    xit 'have facets for date' do
      click_button 'Date Published'
      expect(page).to have_css('span.facet-label > a.facet-select', text: '1865')
    end

    it 'have facets for type' do
      click_button 'Type'
      expect(page).to have_css('span.facet-label > a.facet-select', text: 'Articles')
    end

    it 'does not have facet for resource type' do
      expect(page).not_to have_content('Resource Type')
    end

    it '\'more \' link for subject facets is present' do
      within('div.blacklight-subject_ssim') do
        click_button 'Subject'
        expect(page).to have_link 'more'
      end
    end

    context 'clicking on \'more \' link', js: true do
      before do
        within('div.blacklight-subject_ssim') do
          click_button 'Subject'
          click_link 'more'
        end
      end

      xit 'opens dialog box with correct title' do
        within('#blacklight-modal') do
          expect(page).to have_content 'Subject'
        end
      end

      xit 'shows all six facets' do
        within('#blacklight-modal') do
          ['Nonsense literature', 'Bildungsromans', 'Rabbits', 'Tea Parties', 'Wonderland', 'Magic'].each do |subject|
            expect(page).to have_link subject
          end
        end
      end
    end
  end
end
