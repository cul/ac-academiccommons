# frozen_string_literal: true

require 'date'

class Users::TokensController < ApplicationController
  before_action :authenticate_user!, only: :create

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

  def update
    old_token = current_user_token
    old_token.destroy

    new_token = current_user_token
    http_status = new_token.persisted? ? 200 : 500

    respond_to do |f|
      f.html do
        set_flash!(new_token, :update)
        redirect_to account_path
      end
      f.json { render json: { message: flash_message(token, :update) }, http_status: http_status }
    end
  end

  # Right now, we create an MCP scoped token by default!
  def create
    token = current_user_token
    http_status = token.persisted? ? 200 : 500

    respond_to do |f|
      f.html do
        set_flash!(token, :create)
        redirect_to account_path
      end
      f.json { render json: { message: flash_message(token, :create) }, status: http_status }
    end
  end

  private

  def flash_message(token, action)
    return token.errors.full_messages.to_sentence unless token.persisted?

    case action
    when :create
      'Successfully created API token.'
    when :update
      'Successfully refreshed API token.'
    end
  end

  def set_flash!(token, action)
    flash_type = token.persisted? ? :success : :error
    message = flash_message(token, action)
    flash[flash_type] = message
  end
end
