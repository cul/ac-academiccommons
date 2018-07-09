module Admin
  class DepositsController < AdminController
    load_and_authorize_resource

    def index
      @deposits = Deposit.order(created_at: :desc)
    end

    def show
      @deposit = Deposit.find(params[:id])
    end
  end
end
