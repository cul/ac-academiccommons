# frozen_string_literal: true

require 'rails_helper'

describe 'admin', type: :feature do
  context 'when admin user' do
    include_context 'admin user for feature'

    before do
      visit admin_path
    end

    it 'renders admin dashboard panel button' do
      within('#dashboard-nav') do
        expect(page).to have_link 'Admin', href: admin_path
      end
    end

    it 'renders admin dashboard' do
      expect(page).to have_current_path admin_path
      expect(page).to have_content 'Choose an item from the Administration menu.'
    end

    it 'renders user admin sidebar' do
      expect(page).to have_css '.admin-sidebar'
    end
  end
end
