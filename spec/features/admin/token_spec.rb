# frozen_string_literal: true

require 'rails_helper'

describe 'admin token management', js: true, type: :feature do
  include_context 'admin user for feature'

  context 'when there are no tokens' do
    context 'when visiting the token management page' do
      it 'does not show the table' do
        visit admin_tokens_path
        expect(page).not_to have_css('table#api-tokens-table')
      end
    end
  end

  context 'when there are tokens' do
    before do
      current_user = User.find_by(uid: 'ta123')
      FactoryBot.create(:mcp_token, authorizable: current_user)
      FactoryBot.create(:token)
      visit admin_tokens_path
    end

    context 'when visiting the token management page' do
      it 'displays the api tokens management table' do
        find(:table, 'API Tokens')
      end

      it 'lists all API Tokens' do
        expect(all('tbody tr').length).to eq(Token.all.length)
      end

      it 'lists token owner' do
        find('td', text: 'Test Admin')
        find('td', text: 'Test Service')
      end

      it 'lists token scope' do
        find('td', text: 'MCP')
        find('td', text: 'DATA_FEED')
      end

      it 'includes a delete button for each row' do
        expect(all(:button, 'Delete Token').length).to eq(2)
      end

      it 'includes a show/hide toggle for each row' do
        expect(all(:button, 'Show Value').length).to eq(2)
      end
    end

    context 'when showing/hiding tokens' do
      it 'initially hides all tokens' do
        expect(page).not_to have_css('td', text: 'mcp-token-value')
      end

      it 'clicking toggle shows the token' do
        all(:button, 'Show Value').first.click
        find('td', text: Token.first.token)
        # all(:button, 'Show Value').find { |node| node.}
      end
    end

    context 'when deleting an API token' do
      it 'renders flash message' do
        accept_confirm { all(:button, text: 'Delete Token').first.click }
        find(:table, 'API Tokens')
        expect(page).to have_content('Token successfully deleted.')
      end

      it 'removes the row from the table' do
        accept_confirm { all(:button, text: 'Delete Token').first.click }
        expect(page).to have_content('Token successfully deleted.')
        expect(all(:button, 'Delete Token').length).to eq(1)
      end
    end
  end
end
