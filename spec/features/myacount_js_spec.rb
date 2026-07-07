require 'rails_helper'

describe 'My Account', type: :feature, js: true do
  include_context 'non-admin user for feature'

  before do
    visit account_path
  end

  context 'refreshing a token' do
    let(:current_user) { User.find_by(uid: 'tu123') }

    before do
      FactoryBot.create(:mcp_token, authorizable: current_user)
      visit account_path
    end

    it 'renders a confirmation dialog' do
      accept_confirm { click_button 'Generate New Token' }
      expect(page).to have_field('Personal MCP API Token', disabled: true)
    end
  end

  context 'deleting a token' do
    let(:current_user) { User.find_by(uid: 'tu123') }

    before do
      FactoryBot.create(:mcp_token, authorizable: current_user)
      visit account_path
    end

    it 'renders a confirmation dialog' do
      accept_confirm { click_button 'Delete Token' }
      expect(page).not_to have_field('Personal MCP API Token', disabled: true)
    end
  end
end
