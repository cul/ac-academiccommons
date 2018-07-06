class AdminController < ApplicationController
  authorize_resource
  layout 'admin'

  def agreements
      @agreements = Agreement.all
      respond_to do |format|
         format.html
         format.csv { send_data Agreement.to_csv }
      end
  end
end
