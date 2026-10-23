# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'id-constrained routes', type: :routing do
  let(:valid_doi) { '10.7916/ewq2-2k56' }
  let(:valid_ac_id) { 'ac:12345' }
  let(:invalid_id) { '12345' }

  describe 'doi/*id/download' do
    it 'routes a valid DOI to assets#download' do
      expect(get: "/doi/#{valid_doi}/download")
        .to route_to(controller: 'assets', action: 'download', id: valid_doi)
    end

    it 'routes a valid ac: id to assets#download' do
      expect(get: "/doi/#{valid_ac_id}/download")
        .to route_to(controller: 'assets', action: 'download', id: valid_ac_id)
    end

    it 'does not route an invalid id' do
      expect(get: "/doi/#{invalid_id}/download").not_to be_routable
    end
  end

  describe 'doi/*id/embed' do
    it 'routes a valid DOI to assets#embed' do
      expect(get: "/doi/#{valid_doi}/embed")
        .to route_to(controller: 'assets', action: 'embed', id: valid_doi)
    end

    it 'routes a valid ac: id to assets#embed' do
      expect(get: "/doi/#{valid_ac_id}/embed")
        .to route_to(controller: 'assets', action: 'embed', id: valid_ac_id)
    end

    it 'does not route an invalid id' do
      expect(get: "/doi/#{invalid_id}/embed").not_to be_routable
    end
  end

  describe 'doi/*id/captions' do
    it 'routes a valid DOI to assets#captions' do
      expect(get: "/doi/#{valid_doi}/captions")
        .to route_to(controller: 'assets', action: 'captions', id: valid_doi)
    end

    it 'routes a valid ac: id to assets#captions' do
      expect(get: "/doi/#{valid_ac_id}/captions")
        .to route_to(controller: 'assets', action: 'captions', id: valid_ac_id)
    end

    it 'does not route an invalid id' do
      expect(get: "/doi/#{invalid_id}/captions").not_to be_routable
    end
  end

  describe 'doi/*id (solr_document show)' do
    it 'routes a valid DOI to catalog#show' do
      expect(get: "/doi/#{valid_doi}")
        .to route_to(controller: 'catalog', action: 'show', id: valid_doi)
    end

    it 'routes a valid ac: id to catalog#show' do
      expect(get: "/doi/#{valid_ac_id}")
        .to route_to(controller: 'catalog', action: 'show', id: valid_ac_id)
    end

    it 'does not route an invalid id' do
      expect(get: "/doi/#{invalid_id}").not_to be_routable
    end
  end
end
