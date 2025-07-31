# frozen_string_literal: true

require 'rails_helper'

describe Admin::SiteConfigurationsController, type: :controller do
  describe 'GET edit' do
    include_examples 'authorization required' do
      let(:http_request) { get :edit }
    end

    describe ''
  end

  describe 'PATCH update' do
    include_examples 'authorization required' do
      let(:http_request) { patch :update, params: { deposits_enabled: false } }
    end
  end
end
