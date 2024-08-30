module Admin
  class SiteOptionsController < AdminController
    load_and_authorize_resource class: SiteOption

    def update
      option = SiteOption.find_by(name: "deposits_enabled")
      option.update(value: params["enable_deposits"])
       redirect_back fallback_location: { controller: 'admin/deposits', action: 'index' }
    end

  end
end
