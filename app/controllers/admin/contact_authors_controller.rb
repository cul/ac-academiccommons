# frozen_string_literal: true

module Admin
  class ContactAuthorsController < AdminController
    authorize_resource class: ContactAuthorsForm

    def new
      @contact_authors_form ||= ContactAuthorsForm.new # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def create
      @contact_authors_form = ContactAuthorsForm.new(contact_authors_params)
      if @contact_authors_form.send_emails
        flash[:success] = 'Email successfully sent!'
        redirect_to action: :new
      else
        flash[:error] = @contact_authors_form.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    private

    def contact_authors_params
      params.require(:contact_authors_form).permit(:send_to, :unis, :subject, :body)
    end
  end
end
