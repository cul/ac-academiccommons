module Admin
  class UsageStatisticsReportsController < AdminController
    load_and_authorize_resource class: Statistic

    def new
      @usage_statistics_reports_form ||= UsageStatisticsReportsForm.new
    end

    def create
      @usage_statistics_reports_form = UsageStatisticsReportsForm.new(usage_statistics_reports_params)
      @usage_statistics_reports_form.requested_by = current_user

      if @usage_statistics_reports_form.generate_statistics
        respond_to do |f|
          f.html { render :new }
          f.csv  { send_data @usage_statistics_reports_form.to_csv, type: 'application/csv', filename: 'usage_statistics.csv' }
        end
      else
        flash[:error] = @usage_statistics_reports_form.errors.full_messages.to_sentence
        render :new
      end
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
