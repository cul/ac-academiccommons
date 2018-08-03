module Admin
  class UsageStatisticsReportsController < AdminController
    load_and_authorize_resource class: Statistic

    def new
      @usage_statistics_reports_form ||= UsageStatisticsReportsForm.new
    end

    def create
      @usage_statistics_reports_form = UsageStatisticsReportsForm.new(usage_statistics_reports_params)

      if @usage_statistics_reports_form.generate_statistics
        render :new
      else
        flash[:error] = @usage_statistics_reports_form.errors.full_messages.to_sentence
        render :new
      end
    end

    private

    def usage_statistics_reports_params
      params.require(:usage_statistics_reports_form).permit(:time_period, :order, :options, :display, filters: %i[field value])
    end
  end
end
