require 'rails_helper'

# Emails do not show up in the deliveries array immediately after submitting the
# form, so we wait for the array to be populated
def wait_for_email(timeout: Capybara.default_max_wait_time)
  Timeout.timeout(timeout) do
    loop do
      email = ActionMailer::Base.deliveries.last
      break email unless email.nil?

      sleep 0.1
    end
  end
end

describe 'Usage Statistics Form', type: :feature, js: true do
  context 'when submitting form with all necessary parameters' do
    include_context 'admin user for feature'

    before do
      visit new_admin_usage_statistics_report_path
      select 'Genre', from: 'usage_statistics_reports_form[filters][][field]'
      fill_in 'usage_statistics_reports_form[filters][][value]', with: 'Articles'
      choose 'Lifetime'
      choose 'Summary'
      select 'Most Views', from: 'Order'
      click_button 'Generate Report'
    end

    it 'renders document title' do
      expect(page).to have_content 'Alice\'s Adventures in Wonderland'
    end

    it 'renders details about statistics calculated' do
      expect(page).to have_content 'Period Covered by Report: Lifetime'
      expect(page).to have_content 'Total number of items: 1'
    end

    it 'provides button to download csv' do
      expect(page).to have_button 'Export Results to CSV'
    end

    it 'provides button to create email' do
      expect(page).to have_button 'Email Results'
    end

    it 'fills out form with previously selected parameters' do
      expect(page).to have_checked_field 'Lifetime'
      expect(page).to have_checked_field 'Summary'
      expect(page).to have_select 'Order', selected: 'Most Views'
    end

    context 'when clicking on email button' do
      before do
        click_button 'Email Results'
      end

      xit 'renders modal' do
        expect(page).to have_content 'Email Usage Statistics'
        expect(page).not_to have_content 'Select parameters to calculate usage statistics by work:'
      end

      context 'when submitting email form' do
        let(:email) { wait_for_email }

        before do
          ActionMailer::Base.deliveries.clear
          fill_in 'To', with: 'example@example.com'
          fill_in 'Subject', with: 'Testing Usage Statistics'
          fill_in 'Body', with: 'Below are the Academic Commons statistics that you requested'
          choose 'Yes'
          click_button 'Send Email'
        end

        it 'displays success message' do
          expect(page).to have_content 'Email was sent successfully.'
        end

        it 'email contains attachment' do # TODO: fix me
          expect(email.attachments[0].filename).to eq 'academic_commons_statistics.csv'
        end

        it 'sends email' do # TODO: fix me
          expect(email.to).to include 'example@example.com'
          expect(email.subject).to eql 'Testing Usage Statistics'
          expect(email.html_part.body).to include 'Below are the Academic Commons statistics that you requested'
          expect(email.html_part.body).to include 'Alice\'s Adventures in Wonderland'
        end
      end
    end
  end
end
