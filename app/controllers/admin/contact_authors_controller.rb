module Admin
  class ContactAuthorsController < AdminController
    authorize_resource class: ContactAuthorsForm

    def new
      @contact_authors_form ||= ContactAuthorsForm.new
      # Render app/view/admin/email_author_message/new.html.erb
      # on submit -> POST admin/email_author_message#create
    end

    def create
      Rails.logger.debug('ContactAuthorsController#create: Entry')
      @contact_authors_form = ContactAuthorsForm.new(contact_authors_params)
      if @contact_authors_form.send_emails
          # TODO : how to flash success???
          # Ask Jack
        # flash[:success] = @contact_authors_form.message # TODO implement
        flash[:success] = 'Email was successfully sent!'
        redirect_to action: :new
      else
        flash[:error] = @contact_authors_form.errors.full_messages.to_sentence
        render :new
      end
    end

    private

    def contact_authors_params
      params.require(:contact_authors_form).permit(:send_to, :unis, :subject, :body)
    end
  end
end
