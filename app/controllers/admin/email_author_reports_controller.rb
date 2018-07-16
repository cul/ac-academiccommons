module Admin
  class EmailAuthorReportsController < AdminController
    authorize_resource class: EmailAuthorReportsForm

    def new
      @email_author_reports_form ||= EmailAuthorReportsForm.new
    end

    def create
      @email_author_reports_form = EmailAuthorReportsForm.new(email_author_reports_params)
      if @email_author_reports_form.send_emails
        flash[:success] = 'Emails send to recipients.'
        redirect_to action: :new
      else
        flash[:error] = @email_author_reports_form.errors.full_messages.to_sentence
        render :new
      end
    end

    private

    def email_author_reports_params
      params.require(:email_author_reports_form).permit(:reports_for, :uni, :month, :year, :order_works_by, :optional_note, :deliver, :email)
    end
  end
end
