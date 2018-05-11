require 'rails_helper'

describe 'Browse Pages', type: :feature do
  describe 'department browse' do
    before { visit departments_browse_path }
    let(:authors) { 'Weird Old Guys' }
    let(:department) { 'Bucolic Literary Society' }

    xit 'has indexed departments listed' do
      expect(page).to have_content(department)
      click_on department
      expect(page).to have_link(authors)
    end
  end

  describe 'subjects browse' do
    before do
      visit subjects_browse_path
    end

    xit 'lists two subjects' do
      expect(page).to have_content('Tea Parties')
      expect(page).to have_content('Wonderland')
    end

    xit 'subjects link to page with results' do
      click_on 'Tea Parties'
      expect(page).to have_content 'Alice\'s Adventures in Wonderland'
    end
  end

  describe 'browse' do
    before do
      visit '/catalog/browse'
    end

    xit 'redirects to subject browse' do
      expect(page).to have_current_path '/catalog/browse/subjects'
    end
  end
end
