module Admin
  class UsageStatisticsReportsController < AdminController
    load_and_authorize_resource class: Statistic

    def new
      @usage_statistics_reports_form ||= UsageStatisticsReportsForm.new
    end

    def create
      @usage_statistics_reports_form = UsageStatisticsReportsForm.new(usage_statistics_reports_params)
      @usage_statistics_reports_form.requested_by = current_user

      respond_to do |f|
        if @usage_statistics_reports_form.generate_statistics
          f.html { render :new }
          f.csv  { send_data @usage_statistics_reports_form.to_csv, type: 'application/csv', filename: 'usage_statistics.csv' }
        else
          flash[:error] = @usage_statistics_reports_form.errors.full_messages.to_sentence
          f.html { render :new }
          f.csv  { head :unprocessable_entity }
        end
      end
    end

    def email
      email_parameters = usage_statistics_reports_params.merge(email_params)
      @usage_statistics_reports_form = UsageStatisticsReportsEmailForm.new(email_parameters)
      @usage_statistics_reports_form.requested_by = current_user

      respond_to do |f|
        if @usage_statistics_reports_form.send_email
          f.json { head :ok }
        else
          f.json { render json: @usage_statistics_reports_form.errors.full_messages.to_sentence, status: :unprocessable_entity }
        end
      end
    end

    def email_params
      params.require(:email).permit(:to, :subject, :body, :csv)
    end

    def usage_statistics_reports_params
      params.require(:usage_statistics_reports_form).permit(
        :time_period, :order, :display,
        filters: %i[field value],
        start_date: {},
        end_date: {}
      )
    end
  end
end
