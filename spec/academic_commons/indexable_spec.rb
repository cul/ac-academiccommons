require 'rails_helper'

RSpec.describe AcademicCommons::Indexable do
  let(:mods_fixture) { File.read('spec/fixtures/actest_3/mods.xml') }
  let(:expected_json) { JSON.load File.read('spec/fixtures/actest_1/to_solr.json') }
  let(:indexable) do
    class_rig = Class.new
    class_rig.class_eval do
      include AcademicCommons::Indexable
      def belongsTo; end
      def descMetadata_content; end
      def pid; end
    end
    indexable = class_rig.new
    allow(indexable).to receive(:pid).and_return('actest:1')
    allow(indexable).to receive(:belongsTo).and_return(['collection:3'])
    allow(indexable).to receive(:descMetadata_content).and_return mods_fixture
    indexable
  end
  subject { indexable.index_descMetadata }

  describe "#index_descMetadata" do
    it  { is_expected.to eql(expected_json) }
  end
end
