require 'rails_helper'

RSpec.describe 'Upload', type: :feature do
  # rubocop:disable all
  describe 'index', js: true do
    before do
      visit deposit_path
    end

    xit 'renders title' do
      expect(page).to have_content 'Academic Commons Self-Deposit'
    end

    xit 'contains a Start Here button' do
      expect(page).to have_button('Start Here')
    end

    xit 'does not display the user agreement' do
      expect(page).not_to have_content 'Read and Accept Author Agreement'
    end

    context 'after clicking Start Here' do
      before do
        click_button 'Start Here'
      end

      xit 'cannot continue until user has agreed' do
        click_button 'Continue'
        expect(page).to have_content 'You must accept the Author Rights Agreement to continue.'
        expect(page).to have_content 'Step 1 of 3'
      end

      context 'once user has agreed' do
        before do
          check 'acceptedAgreement'
          click_button 'Continue'
        end

        xit 'renders next page' do
          expect(page).to have_content 'Required Information'
          expect(page).to have_content 'Step 2 of 3'
        end

        context 'once deposit information is entered' do
          before do
            fill_in('name', with: 'John Doe')
            fill_in('email', with: 'xyz123@columbia.edu')
            attach_file('file', fixture('test_file.txt'))
            fill_in('title', with: 'Test Deposit')
            fill_in('author', with: 'John Doe')
            fill_in('abstr', with: 'Blah Blah Blah')
            click_button 'Continue'
          end

          context 'when user submits' do
            before do
              click_button 'Submit'
            end

            after do
              FileUtils.rm(Rails.root.join(Deposit.first.file_path)) # Remove file deposited
            end

            xit 'renders submission confirmation' do
              expect(page).to have_content 'We Have Received Your Submission'
            end

            xit 'creates deposit record' do
              expect(Deposit.count).to eq 1
            end
          end
        end
      end
    end
  end
  # rubocop:enable all
end
