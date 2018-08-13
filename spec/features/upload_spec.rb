require 'rails_helper'

RSpec.describe 'Upload', type: :feature do
  context 'when user not logged in' do
    before { visit uploads_path }

    it 'contains sign in link' do
      within('.log-in') do
        expect(page).to have_content 'Have a Columbia UNI?'
        expect(page).to have_link 'Log In', href: '/sign_in'
      end
    end

    it 'contains option for users without login' do
      within('.no-log-in') do
        expect(page).to have_content 'No Columbia UNI?'
        expect(page).to have_content 'ac@columbia.edu'
      end
    end
  end

  context 'when user logged in', js: true do
    include_context 'non-admin user for feature'

    before do
      visit uploads_path
    end

    it 'display status of agreement' do
      expect(page).to have_content 'PARTICIPATION AGREEMENT'
    end

    it 'render title field' do
      expect(page).to have_field 'Title*'
    end

    it 'render abstract field' do
      expect(page).to have_field 'Abstract*'
    end

    it 'render year field' do
      expect(page).to have_field 'Year Created*'
    end

    it 'render doi/url field' do
      expect(page).to have_field 'DOI/URL'
    end

    it 'render notes field' do
      expect(page).to have_field 'Notes'
    end

    it 'renders student checkbox' do
      expect(page).to have_unchecked_field('Check here if you are a current student at Columbia or one of its affiliate institutions.')
    end

    it 'contains creator field with user\'s information' do
      expect(page).to have_field 'deposit[creators][][first_name]', with: 'Test'
      expect(page).to have_field 'deposit[creators][][last_name]',  with: 'User'
      expect(page).to have_field 'deposit[creators][][uni]',        with: 'tu123'
    end

    it 'allows addition of creators' do
      click_button 'Add another creator'
      expect(page).to have_field 'deposit[creators][][first_name]', count: 2
      expect(page).to have_field 'deposit[creators][][last_name]',  count: 2
      expect(page).to have_field 'deposit[creators][][uni]',        count: 2
    end

    context 'when user selects "No Copyright"' do
      before do
        select 'No Copyright', from: 'Copyright Status*'
      end

      it 'renders "Use by Others" with correct licenses' do
        expect(page).to have_select 'Use by Others*', options: ['CC0']
      end
    end

    context 'when use selects "In Copyright"' do
      let(:license_options) do
        [
          'Use by others as provided for by copyright laws - All rights reserved',
          'Attribution (CC BY)',
          'Attribution-ShareAlike (CC BY-SA)',
          'Attribution-NoDerivs (CC BY-ND)',
          'Attribution-NonCommercial (CC BY-NC)',
          'Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)',
          'Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)'
        ]
      end

      before do
        select 'In Copyright', from: 'Copyright Status*'
      end

      it 'renders "Use of Others" with correct license' do
        expect(page).to have_select('Use by Others*', options: license_options)
      end
    end

    it 'contains file field' do
      expect(page).to have_css 'input[type="file"]', visible: false
    end

    context 'when submitting form with all required data' do
      before do
        fill_in 'Title*', with: 'Test Deposit'
        fill_in 'Abstract*', with: 'Blah Blah Blah'
        fill_in 'Year Created*', with: '2017'
        select 'No Copyright', from: 'Copyright Status*'
        attach_file nil, fixture('test_file.txt'), class: 'dz-hidden-input', visible: false
        click_button 'Submit'
      end

      it 'renders submission confirmation' do
        expect(page).to have_content 'Thank you for uploading your work to Academic Commons.'
      end

      it 'creates deposit record' do
        deposit = Deposit.last
        expect(deposit.title).to eql 'Test Deposit'
        expect(deposit.creators).to eql [{ 'first_name' => 'Test', 'last_name' => 'User', 'uni' => 'tu123' }]
      end
    end

    context 'when submitting form with missing required data' do
      before do
        fill_in 'Title*', with: 'Test Deposit'
        fill_in 'Abstract*', with: 'Blah Blah Blah'
        fill_in 'Year Created*', with: '2017'
        click_button 'Submit'
      end

      it 'redirects to /new' do
        expect(page).to have_current_path uploads_path
      end

      it 'fills in already filled in values' do
        expect(page).to have_field 'Title*', with: 'Test Deposit'
        expect(page).to have_field 'Abstract*', with: 'Blah Blah Blah'
        expect(page).to have_field 'Year Created*', with: '2017'
      end

      it 'render error message' do
        expect(page).to have_css(
          '.flash_messages > .alert-danger',
          text: 'Rights can\'t be blank, Rights is not included in the list, and Files can\'t be blank'
        )
      end
    end
  end
end
