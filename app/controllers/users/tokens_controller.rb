# frozen_string_literal: true

require 'date'

class Users::TokensController < ApplicationController
  before_action :authenticate_user!, only: :create

  def current_user_token
    token_args = {
      authorizable: current_user, scope: Token::API
    }
    Token.find_or_create_by(token_args) do |token|
      token.token = SecureRandom.hex(32)
      token.contact_email = current_user.email
      token.description = "#{current_user.uid} personal api token"
    end
  end

  def flash_message(token, as_of)
    if token.persisted?
      newly_created = as_of <= token.created_at
      newly_created ? 'Successfully created API token.' : 'Request help to refresh API token.'
    else
      token.errors.full_messages.to_sentence
    end
  end

  def set_flash!(as_of, token)
    flash_type = token.persisted? ? :success : :error
    flash_msg = flash_message(token, as_of)
    flash[flash_type] = flash_msg
  end

  def create
    as_of = DateTime.now

    token = current_user_token
    http_status = token.persisted? ? 200 : 500

    respond_to do |f|
      f.html do
        set_flash!(as_of, token)
        redirect_to account_path
      end
      f.json { render json: { message: flash_message(token, as_of) }.to_json, status: http_status }
    end
  end
end
