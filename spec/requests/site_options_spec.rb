# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SiteOptions', type: :request do
  describe 'PATCH /site_options' do
    include_context 'admin user for feature'
    before do
      stub_const('SiteOption::OPTIONS', ['test_option'])
    end

    context 'when changing existing option setting' do
      let!(:site_option) { FactoryBot.create(:site_option, name: 'test_option') }

      before do
        get '/admin'
        patch admin_site_options_path, params: {
          test_option: true
        }
      end

      it 'updates site option value' do
        expect(site_option.reload.value).to eq(true)
      end
    end

    context 'when setting option for the first time' do
      before do
        get '/admin'
      end

      it 'successfully creates site option with value' do
        expect {
          patch admin_site_options_path, params: {
            test_option: true
          }
        }.to change(SiteOption, :count).from(0).to(1)
      end
    end
  end
end
