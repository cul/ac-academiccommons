# frozen_string_literal: true

module Admin
  class TokensController < AdminController
    load_and_authorize_resource

    def index; end

    def destroy
      @token.destroy!
      flash[:success] = 'Token successfully deleted.'
      redirect_to action: :index
    rescue StandardError
      flash[:error] = 'There was an error deleting this token'
      redirect_to action: :index
    end
  end
end
