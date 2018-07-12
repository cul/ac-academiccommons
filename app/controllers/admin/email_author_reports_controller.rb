module Admin
  class EmailAuthorReportsController < AdminController
    load_and_authorize_resource class: EmailAuthorReportsForm

    def new
      @email_author_reports_form ||= EmailAuthorReportsForm.new
    end

    def create; end
  end
end
