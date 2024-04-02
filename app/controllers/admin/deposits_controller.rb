module Admin
  class DepositsController < AdminController
    load_and_authorize_resource

    def index
      @deposits = Deposit.paginate(page: params[:page], per_page: 30).order(created_at: :desc)
    end

    def show
      @deposit = Deposit.find(params[:id])
    end
  end
end
