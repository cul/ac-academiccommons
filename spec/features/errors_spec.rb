# frozen_string_literal: true

require 'rails_helper'

describe 'error pages', type: :feature do
  context 'when visiting 404 page (not found)' do
    before do
      visit '/this_page_does_not_exist'
    end

    it 'displays custom 404 error message' do
      expect(page).to have_content "The page you are looking for doesn't exist."
      expect(page).to have_link 'homepage', href: root_path
    end
  end

  context 'when visiting a 404 page for a blacklight record (record not found)' do
    before do
      allow_any_instance_of(CatalogController).to receive(:show).and_raise(Blacklight::Exceptions::RecordNotFound) # rubocop:disable RSpec/AnyInstance
      visit solr_document_path('nonexistent_id')
    end

    it 'displays custom record not found error message' do
      expect(page).to have_content 'This item does not exist in Academic Commons or may have been removed.'
    end
  end

  context 'when visiting 500 page (internal server error)' do
    before do
      allow_any_instance_of(CatalogController).to receive(:index).and_raise(StandardError) # rubocop:disable RSpec/AnyInstance
    end

    it 'displays custom 500 error message' do
      visit search_catalog_path
      expect(page).to have_content 'Internal Server Error'
    end
  end

  context 'when visiting 403 page (forbidden)' do
    include_context 'non-admin user for feature'

    before do
      visit admin_path
    end

    it 'displays custom 403 error message' do
      expect(page).to have_content 'You do not have access.'
    end
  end
end
