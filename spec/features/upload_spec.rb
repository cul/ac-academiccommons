# frozen_string_literal: true

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

  context 'when user logged in, but has not signed agreement', js: true do
    include_context 'non-admin user for feature'

    before do
      visit uploads_path
    end

    it 'display status of agreement' do
      expect(page).to have_content 'To upload your research, you must sign the Academic Commons participation agreement.'
    end

    it 'disabled title field' do
      expect(page).to have_field 'Title*', disabled: true
    end
  end

  context 'when user logged in', js: true do
    include_context 'non-admin user for feature'

    before do
      # Added signed agreement for logged in user, tried mocking :signed_latest_agreement? but it did not work
      Agreement.create(user: User.first, name: 'Test User', email: 'tu123@columbia.edu', agreement_version: Agreement::LATEST_AGREEMENT_VERSION)
      visit uploads_path
    end

    it 'display status of agreement' do
      expect(page).to have_content 'You have signed the Academic Commons participation agreement.'
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

    it 'renders student radio buttons' do
      expect(page).to have_unchecked_field 'deposit[current_student]'
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

    it 'contains file field' do
      expect(page).to have_css 'input[type="file"]', visible: false
    end

    context 'when user is a current student' do
      before do
        choose('deposit[current_student]', option: true)
      end

      it 'contains degree program input' do
        expect(page).to have_css 'input[name="deposit[degree_program]"]'
      end
    end

    context 'when user is not a current student' do
      before do
        choose('deposit[current_student]', option: false)
      end

      it 'does not contain academic advisor input' do
        expect(page).not_to have_css 'input[name="deposit[academic_advisor]"]', visible: true
      end
    end

    context 'when student submits form with all required data' do
      before do
        choose('deposit[current_student]', option: true)
        fill_in 'Title*', with: 'Test Deposit'
        fill_in 'Abstract*', with: 'Blah Blah Blah'
        fill_in 'Year Created*', with: '2017'
        fill_in 'deposit[academic_advisor]', with: 'Advisor Name'
        fill_in 'Degree Program*', with: 'Economics'
        choose 'deposit[thesis_or_dissertation]', option: 'dissertation'
        choose 'deposit[license]', option: 'https://creativecommons.org/publicdomain/zero/1.0/'
        choose 'deposit[previously_published]', option: true
        attach_file nil, fixture('test_file.txt'), class: 'dz-hidden-input', visible: false
        # sleep(3) # Adding sleep so file properly attaches
        click_button 'Submit'
        # do a find to make sure page loaded and action completed
        find('h3', text: 'Thank you for uploading your work to Academic Commons.')
      end

      it 'renders submission confirmation' do
        expect(page).to have_content 'Thank you for uploading your work to Academic Commons.'
      end

      it 'creates deposit record' do
        deposit = Deposit.last
        expect(deposit.title).to eql 'Test Deposit'
        expect(deposit.creators).to eql [{ 'first_name' => 'Test', 'last_name' => 'User', 'uni' => 'tu123' }]
      end

      it 'sends student reminder email' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.subject).to eql 'Department approval may be needed'

        expect(email.to).to include User.first.email
      end

      it 'appears in the myworks list' do
        visit myworks_path
        expect(page).to have_content 'Test Deposit'
      end

      it 'appears in the myworks list as pending' do
        visit myworks_path
        within '[data-testid="pending-works-table"]' do
          expect(page).to have_content 'Test Deposit'
        end
      end

      it 'appears in the admin self-deposits list' do
        logout(:user)
        login_as FactoryBot.create(:admin), scope: :user
        visit admin_deposits_path
        expect(page).to have_content 'Test Deposit'
      end

      it 'is downloadable within the admin self-deposits section' do
        deposit = Deposit.last
        visit admin_deposit_path(deposit)
        expect(page).to have_link 'test_file.txt', href: rails_blob_path(deposit.files.first, disposition: 'attachment')
      end
    end

    context 'when student submits form with missing required data' do
      before do
        choose('deposit[current_student]', option: true)
        fill_in 'Title*', with: 'Test Deposit'
        fill_in 'Abstract*', with: 'Blah Blah Blah'
        fill_in 'Year Created*', with: '2017'
        # missing field: file-upload
        click_button 'Submit'
      end

      it 'redirects to /new' do
        expect(page).to have_current_path new_upload_path
      end

      #  todo : failing
      it 'fills in already filled in values' do
        expect(page).to have_field 'Title*', with: 'Test Deposit'
        expect(page).to have_field 'Year Created*', with: '2017'
        expect(page).to have_field 'Abstract*', with: 'Blah Blah Blah'
      end

      it 'renders error messages' do
        expect(page).to have_css(
          '.flash_messages > .alert-danger',
          text: 'Files can\'t be blank, Previously published is not included in the list, Degree program can\'t be blank, Academic advisor can\'t be blank, and Thesis or dissertation can\'t be blank'
        )
      end
    end
  end
end
