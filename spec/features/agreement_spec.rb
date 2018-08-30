require 'rails_helper'

describe 'Agreement', type: :feature do
  include_context 'non-admin user for feature'

  before do
    visit agreement_path
  end

  it 'renders agreement title' do
    expect(page).to have_css('h2', text: 'Columbia Academic Commons Deposit Agreement')
  end

  it 'renders agreement form' do
    expect(page).to have_css('form.agreement')
  end

  it 'shows error when fields missing' do
    click_button 'Accept'
    expect(page).to have_css('div.alert-danger', text: 'You must accept the participation agreement')
  end

  context 'when submitting agreement form' do
    before do
      check 'I have read and accept the participation agreement.'
      fill_in 'Name', with: 'Test User'
      fill_in 'E-mail', with: 'test@columbia.edu'
      click_button 'Accept'
    end

    it 'show acceptance alert' do
      expect(page).to have_css('div.alert-info', text: 'Author Agreement Accepted')
    end

    it 'renders upload new work page' do
      expect(page).to have_css('li.active', text: 'Add New Work')
    end

    context 'return to agreement form' do
      before do
        click_link 'Read the agreement'
      end

      it 'show already signed alert' do
        expect(page).to have_css('p.alert-info', text: 'You have already signed this agreement')
      end

      it 'renders agreement form' do
        expect(page).not_to have_css('form.agreement')
      end
    end
  end
end
