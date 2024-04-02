module Admin
  class AgreementsController < AdminController
    load_and_authorize_resource

    def index

      @agreements = Agreement.paginate(page: params[:page], per_page: 30)
      respond_to do |format|
        format.html
        format.csv { send_data Agreement.to_csv }
      end
    end
  end
end
