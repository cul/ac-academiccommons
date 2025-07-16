# frozen_string_literal: true

module Admin
  class DownloadsController < AdminController
    authorize_resource class: false

    def index
      @enabled = downloads_enabled?
    end
  end
end
