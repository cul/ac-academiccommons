module Admin
  class ReportsController < AdminController
    load_and_authorize_resource class: Statistic

    def create; end
  end
end
