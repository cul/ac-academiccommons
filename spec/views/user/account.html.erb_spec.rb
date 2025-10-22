# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'user/account', type: :view do
  let(:email_preference) { FactoryBot.create(:email_preference, uni: test_user.uid, email: test_user.email) }
  let(:test_user) { FactoryBot.create(:user) }
  let(:token) { FactoryBot.create(:token, authorizable: test_user) }

  before do
    allow(view).to receive(:title).with(instance_of(String))
    allow(view).to receive(:current_user).and_return(test_user)
    assign(:email_preference, email_preference)
    assign(:user_api_token, token)
    render
  end

  it 'renders read and sign agreement link' do
    expect(rendered).to have_css('a', text: 'Read and sign the agreement')
  end

  it 'renders token text box label' do
    expect(rendered).to have_css('label', text: 'Personal API Token')
  end

  it 'renders token text box' do
    expect(rendered).to have_selector("//input[@value='#{token.token}']")
  end

  context 'when rendering email preferences' do
    it 'renders header' do
      expect(rendered).to have_css('h3', text: 'Email Preferences')
    end

    it 'renders prompt' do
      expect(rendered).to have_css('p', text: 'You can change your Academic Commons email preferences below.')
    end
  end
end
