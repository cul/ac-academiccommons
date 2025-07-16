# frozen_string_literal: true

module Admin
  class SiteOptionsController < AdminController
    load_and_authorize_resource class: SiteOption

    def update
      option_keys = params.keys.select { |key| SiteOption::OPTIONS.include?(key) }
      option_keys.each do |option_key|
        option = SiteOption.find_by(name: option_key)
        if option.nil?
          option = SiteOption.create!(name: option_key,
                                      value: SiteOption.default_value_for_option(option_key))
        end
        option.update(value: params[option_key])
      end
      redirect_back fallback_location: { controller: '/admin', action: 'index' }
    end
  end
end
