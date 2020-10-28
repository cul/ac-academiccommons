# require 'rails_helper'
# require 'academic_commons'
require './helpers/catalog_helper.rb'

describe CatalogHelper, :type => :helper do
  context do
    before do
      allow(helper).to receive(:related_item_relation_label).and_return(related_item_relation_label)
    end
    let(:document) do
      {
        'related_item_version_of' => (isVersionOf.sub('isVersionOf', 'Another thing')),
        'related_item_previous_version_of' => (isPreviousVersionOf.sub('isPreviousVersionOf', 'Subsequent version')),
        'related_item_new_version_of' => (isNewVersionOf.sub('isNewVersionOf', 'Previous version')),
        'related_item_other' => (isReviewOf.remove(/^is/).underscore.gsub('_', ' ').upcase_first.concat(':'))
      }
    end
    describe '#related_item_version_of' do
      subject { helper.related_item_version_of(document) }
      context "a version of" do
        let(:document_show_link_field) { 'related_item_version_of' }
        it { is_expected.to eql('Another thing') }
      end
    end
    describe '#related_item_previous_version_of' do
      subject { helper.related_item_previous_version_of(document) }
      context "a previous version of" do
        let(:document_show_link_field) { 'related_item_previous_version_of' }
        it { is_expected.to eql('Subsquent version') }
      end
    end
    describe '#related_item_new_version_of' do
      subject { helper.related_item_new_version_of(document) }
      context "a new version of" do
        let(:document_show_link_field) { 'related_item_new_version_of' }
        it { is_expected.to eql('Previous version') }
      end
    end
    describe '#related_item_other' do
      subject { helper.related_item_other(document) }
      context "a review of" do
        let(:document_show_link_field) { 'related_item_other' }
        it { is_expected.to eql('Review of') }
      end        
    end
  end
end