# frozen_string_literal: true
require 'rails_helper'

describe CatalogHelper, type: :helper do
  describe '#related_item_relation_label' do
    subject { helper.related_item_relation_label(document) }
    let(:document) do
      {
        relation_type: relation_type_value
      }
    end

    context "a version of" do
      let(:relation_type_value) { 'isVersionOf' }
      it { is_expected.to eql('Version of:') }
    end

    context "a previous version of" do
      let(:relation_type_value) { 'isPreviousVersionOf' }
      it { is_expected.to eql('Subsequent version:') }
    end

    context "a new version of" do
      let(:relation_type_value) { 'isNewVersionOf' }
      it { is_expected.to eql('Previous version:') }
    end

    context "a review of" do
      let(:relation_type_value) { 'isReviewOf' }
      it { is_expected.to eql('Review of:') }
    end
  end
end
