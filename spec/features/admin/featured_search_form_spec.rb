# frozen_string_literal: true
require 'rails_helper'

describe 'Featured Search Form', type: :feature, js: true do
  context 'when submitting form with all necessary parameters' do
    include_context 'admin user for feature', 'tu123'

    let(:slug) { 'research-center' }
    let(:category) { 'partner' }
    let(:filter_value) { 'Research Center' }
    let(:feature_url) { 'https://researchcenter.columbia.edu' }
    let(:description) { 'Articles and papers from the Research Center.' }
    before do
      Rails.application.load_seed
      visit new_admin_featured_search_path
      select category, from: 'featured_search[feature_category_id]'
      fill_in 'featured_search[slug]', with: slug
      fill_in 'featured_search[label]', with: filter_value
      fill_in 'featured_search[featured_search_values_attributes][0][value]', with: filter_value
      fill_in 'featured_search[url]', with: feature_url
      fill_in 'featured_search[description]', with: description
      click_button 'Submit'
      sleep(1) # unfortunately, without this many of these tests fail indeterminately
    end

    it 'renders document title' do
      expect(page).to have_content "Edit featured search at #{slug}"
    end

    describe 'after creating a featured search', js: false do
      let(:new_featured_search) { FeaturedSearch.find_by(slug: slug) }
      it 'appears in the list features panel' do
        visit admin_featured_searches_path
        expect(page).to have_content 'Featured Searches'
        expect(page).to have_content slug
      end

      it 'has slug link to edit the featured search' do
        visit admin_featured_searches_path
        expect(page).to have_link slug, href: edit_admin_featured_search_path(new_featured_search)
      end

      it 'has filter-value link to edit the featured search' do
        visit admin_featured_searches_path
        expect(page).to have_link filter_value, href: edit_admin_featured_search_path(new_featured_search)
      end

      it 'the slug is a valid search link' do
        visit "/detail/#{new_featured_search.slug}"
        expect(page).to have_current_path("/search?f%5Bfeatured_search%5D%5B%5D=#{new_featured_search.slug}")
      end

      it 'has link to delete the featured search' do
        visit admin_featured_searches_path
        expect(page).to have_link 'Delete', href: admin_featured_search_path(new_featured_search)
      end

      it 'clicking delete renders a confirmation dialog', js: true do
        visit admin_featured_searches_path
        accept_confirm do
          click_link 'Delete', href: admin_featured_search_path(new_featured_search)
        end
        expect(page).to have_content "Deleted feature at #{slug}!"
      end
    end
  end
end
