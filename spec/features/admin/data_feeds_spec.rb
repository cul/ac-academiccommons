# frozen_string_literal: true

require 'rails_helper'

describe 'admin data_feed management', js: true, type: :feature do
  include_context 'admin user for feature'

  context 'when there are no data feeds' do
    before do
      visit admin_data_feeds_path
    end

    it 'does not show the table' do
      expect(page).not_to have_css('table#data-feed-keys-table')
    end

    it 'shows the create button' do
      expect(page).to have_link 'Create a New Data Feed'
    end
  end

  context 'with existing data feeds' do
    let!(:test_feed1) { FactoryBot.create(:data_feed, key: 'feed1') }

    before do
      FactoryBot.create(:data_feed, key: 'feed2')
      FactoryBot.create(:data_feed, key: 'feed3')
    end

    context 'when viewing all data feeds' do
      before do
        visit admin_data_feeds_path
      end

      it 'lists all the managed keys in a table' do
        expect(page).to have_css('table#data-feed-keys-table')
        find('td', text: 'feed1')
        find('td', text: 'feed2')
        find('td', text: 'feed3')
      end

      it 'shows an edit button for each key' do
        expect(all(:link, 'Edit').length).to eq(3)
      end

      it 'shows a delete button for each row' do
        expect(all(:button, 'Delete').length).to eq(3)
      end

      it 'shows a create new data key button' do
        expect(page).to have_link 'Create a New Data Feed'
      end
    end

    context 'when creating a new token' do
      before do
        visit new_admin_data_feed_path
      end

      it 'requires a data feed key value' do
        fill_in 'data_feed[search_fields_attributes][0][key]', with: 'key'
        fill_in 'data_feed[search_fields_attributes][0][value]', with: 'value'
        click_button 'Create Data feed'
        expect(page).to have_content "Key can't be blank"
      end

      it 'requires search field values' do
        fill_in 'data_feed[key]', with: 'feed'
        click_button 'Create Data feed'
        expect(page).to have_content 'must provide both a key and value'
      end

      it 'requires a unique data feed key value' do
        fill_in 'data_feed[search_fields_attributes][0][key]', with: 'key'
        fill_in 'data_feed[search_fields_attributes][0][value]', with: 'value'
        fill_in 'data_feed[key]', with: 'feed3'
        click_button 'Create Data feed'
        expect(page).to have_content 'already been taken'
      end

      it 'renders a flash success method on save' do
        fill_in 'data_feed[key]', with: 'feed'
        fill_in 'data_feed[search_fields_attributes][0][key]', with: 'key'
        fill_in 'data_feed[search_fields_attributes][0][value]', with: 'value'
        click_button 'Create Data feed'
        expect(page).to have_content 'Successfully created data feed'
      end
    end

    context 'when editing a token' do
      before do
        visit edit_admin_data_feed_path(test_feed1.id)
      end

      it 'shows the delete button' do
        expect(page).to have_button 'Delete Data Feed'
      end

      it 'renders a flash success method on save' do
        fill_in 'data_feed[key]', with: 'CHANGE'
        click_button 'Update Data feed'
        expect(page).to have_content 'Successfully updated data feed'
      end
    end
  end
end
