# frozen_string_literal: true
require 'rails_helper'
require 'tmpdir'
describe FeaturedSearch, type: :model do
  let(:featured_search) { FactoryBot.create(:libraries_featured_search) }
  let(:temp_dir) { Dir.tmpdir }
  let(:properties_path) { File.join(temp_dir, FeaturedSearch::PROPERTIES_FILE) }
  let(:description_path) { File.join(temp_dir, FeaturedSearch::DESCRIPTION_FILE) }
  before { featured_search.export(temp_dir) }
  describe '.import' do
    let(:expected) { featured_search.export_attributes }
    let(:import) { FeaturedSearch.import(temp_dir) }
    let(:actual) { import.export_attributes }
    before { FeaturedSearch.find(featured_search.id).destroy }
    it "imports from an export" do
      expect(actual).to eql(expected)
      expect(import.description).to eql(featured_search.description)
    end
  end
  describe '#export' do
    let(:expected_properties) { featured_search.export_attributes }
    let(:expected_description) { featured_search.description }
    it "exports expected properties" do
      actual = YAML.safe_load(File.read(properties_path), aliases: true)
      expect(actual).to eql(expected_properties)
    end
    it "exports expected description" do
      actual = File.read(description_path)
      expect(actual).to eql(expected_description)
    end
  end
  describe '#image_url' do
    it 'returns thumbnail_url when present' do
      expect(featured_search.image_url).to eql(featured_search.thumbnail_url)
    end
    it 'returns category thumbnail_url when absent' do
      featured_search.thumbnail_url = nil
      expect(featured_search.image_url).to eql(featured_search.feature_category.thumbnail_url)
    end
  end
end
