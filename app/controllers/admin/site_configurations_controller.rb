# frozen_string_literal: true

module Admin
  class SiteConfigurationsController < AdminController
    load_and_authorize_resource class: SiteConfiguration

    def update
      if SiteConfiguration.instance.update(site_configuration_params)
        flash[:success] = 'Succesfully updated site option.'
      else
        flash[:error] = 'There was an error updating the site option.'
      end

      render :show
    end

    private

    def site_configuration_params
      params.permit(:alert_message, :deposits_enabled, :downloads_enabled, :downloads_message)
    end
  end
end
