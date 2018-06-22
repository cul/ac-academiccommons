module Admin
  class RequestAgreementsController < ApplicationController
    authorize_resource class: RequestAgreementsForm

    def new
      @request_agreements_form ||= RequestAgreementsForm.new
    end

    def create
      @request_agreements_form = RequestAgreementsForm.new(request_agreements_params)
      if @request_agreements_form.save_and_send_notification
        flash[:success] = 'Request was successfully sent'
        redirect_to action: :new
      else
        flash[:error] = @request_agreements_form.errors.full_messages.to_sentence
        render :new
      end
    end

    def request_agreements_params
      params.require(:request_agreements_form).permit(:name, :email, :uni)
    end
  end
end
