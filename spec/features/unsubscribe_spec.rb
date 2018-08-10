require 'rails_helper'

RSpec.describe 'Unsubscribe', type: :feature do
  let(:uni) { 'abc123' }

  context 'flashes error when' do
    let(:error) { 'There was an error with your unsubscribe request' }

    it 'author_id missing' do
      visit 'unsubscribe_monthly?chk=foo'
      expect(page).to have_content error
    end

    it 'chk missing' do
      visit "unsubscribe_monthly?author_id=#{uni}"
      expect(page).to have_content error
    end

    it 'chk and author_id missing' do
      visit 'unsubscribe_monthly'
      expect(page).to have_content error
    end

    it 'chk incorrect' do
      visit "unsubscribe_monthly?author_id=#{uni}&chk=#{Rails.application.message_verifier(:unsubscribe).generate('abc')}"
      expect(page).to have_content error
    end
  end

  context 'when successful request' do
    before :each do
      visit "unsubscribe_monthly?author_id=#{uni}&chk=#{Rails.application.message_verifier(:unsubscribe).generate(uni)}"
    end

    it 'flashes successful message' do
      expect(page).to have_content 'Unsubscribe request successful'
    end
  end
end
