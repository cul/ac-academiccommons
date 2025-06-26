# frozen_string_literal: true

module Admin
  class DownloadsController < AdminController
    authorize_resource class: false

    def index
      Rails.logger.debug ' ahoy there! entered downloads controller index action!'
      @enabled = downloads_enabled?
      Rails.logger.debug ' ahoy there! trying to render views/admin/downloads/index.html'
    end
  end
end
