# frozen_string_literal: true

module Admin
  class SiteOptionsController < AdminController
    load_and_authorize_resource class: SiteOption

    def index
      puts '------------------------------------------------------------------------------------------'
      puts 'in site options controller - index action'
      @site_options = SiteOption.all
      @downloads_enabled = downloads_enabled?
      @deposits_enabled = deposits_enabled?
      @alert_message ||= ContentBlock.find_by(title: ContentBlock::ALERT_MESSAGE)
      @alert_message ||= ContentBlock.new
    end

    def edit
      puts 'edit'
    end

    def update
      puts 'update'
    end

    def show
      @downloads_enabled = downloads_enabled?
      @deposits_enabled = deposits_enabled?
      @alert_message ||= ContentBlock.find_by(title: ContentBlock::ALERT_MESSAGE)
      @alert_message ||= ContentBlock.new
    end

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
