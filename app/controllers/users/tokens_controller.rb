# frozen_string_literal: true

require 'date'

class Users::TokensController < ApplicationController
  before_action :authenticate_user!, only: :create

  def destroy
    Token.find_by!(authorizable: current_user, scope: Token::MCP).destroy!
    token_response(:success, 'Successfully deleted API token.', :ok)
  rescue StandardError
    token_response(:error, 'Was not able to destroy API token.', :internal_server_error)
  end

  def update
    old_token = current_user_token
    old_token.destroy

    new_token = current_user_token
    http_status = new_token.persisted? ? 200 : 500

    flash_type = new_token.persisted? ? :success : :error
    message = flash_message(new_token, :update)

    token_response(flash_type, message, http_status)
  end

  # Right now, we create an MCP scoped token by default!
  def create
    token = current_user_token
    http_status = token.persisted? ? 200 : 500

    flash_type = token.persisted? ? :success : :error
    message = flash_message(token, :create)

    token_response(flash_type, message, http_status)
  end

  private

  def current_user_token(scope: Token::MCP)
    token_args = {
      authorizable: current_user, scope: scope
    }
    Token.find_or_create_by(token_args) do |token|
      token.token = SecureRandom.hex(32)
      token.contact_email = current_user.email
      token.description = "#{current_user.uid} personal #{scope.upcase} token"
    end
  end

  def flash_message(token, action)
    return token.errors.full_messages.to_sentence unless token.persisted?

    case action
    when :create
      'Successfully created API token.'
    when :update
      'Successfully refreshed API token.'
    end
  end

  def token_response(flash_type, message, http_status)
    respond_to do |f|
      f.html do
        flash[flash_type] = message
        redirect_to account_path
      end
      f.json { render json: { message: message }, status: http_status }
    end
  end
end
