require 'rails_helper'

RSpec.describe AcademicCommons::Indexable do
  let(:mods_fixture) { File.read('spec/fixtures/actest_3/mods.xml') }
  let(:expected_json) { JSON.load File.read('spec/fixtures/actest_1/to_solr.json') }
  let(:indexable) do
    class_rig = Class.new
    class_rig.class_eval do
      include AcademicCommons::Indexable
      def belongs_to; end
      def descMetadata_datastream; end
      def pid; end
    end
    indexable = class_rig.new
    allow(indexable).to receive(:pid).and_return('actest:1')
    allow(indexable).to receive(:belongs_to).and_return(['collection:3'])

    ds_fixture = ActiveFedora::Datastream.new(indexable, 'test_ds')
    allow(ds_fixture).to receive(:content).and_return mods_fixture
    allow(indexable).to receive(:descMetadata_datastream).and_return ds_fixture

    indexable
  end

  subject { indexable.index_descMetadata }

  describe "#index_descMetadata" do
    it  { is_expected.to eql(expected_json) }
  end
end
