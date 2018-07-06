module Admin
  class DepositsController < ApplicationController
    load_and_authorize_resource

    layout 'admin'

    def index
      @deposits = Deposit.order(created_at: :desc)
    end

    def show
      @deposit = Deposit.find(params[:id])
    end
  end
end
