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
    end

    it 'renders document title' do
      expect(page).to have_content "Edit featured search at #{slug}"
    end
  end
end
