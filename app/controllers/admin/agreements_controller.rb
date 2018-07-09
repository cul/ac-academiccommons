module Admin
  class AgreementsController < AdminController
    load_and_authorize_resource

    def index
      @agreements = Agreement.all
      respond_to do |format|
        format.html
        format.csv { send_data Agreement.to_csv }
      end
    end
  end
end
