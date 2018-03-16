require 'rails_helper'
RSpec.describe AcademicCommons::Indexable do
  let(:expected_json) { fixture_to_json('fedora_objs/to_solr.json') }
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

  shared_examples 'indexing mods' do
    subject { indexable.index_descMetadata }

    describe '#index_descMetadata' do
      it  { is_expected.to eql(expected_json) }
    end
  end

  # Tests prefixed MODS with joined names. These changes were introduced with the
  # migration to Hyacinth.
  context 'when mods from Hyacinth' do
    let(:mods_fixture) { fixture_to_str('fedora_objs/mods.xml') }
    include_examples 'indexing mods'

    context 'contains degree information' do
      let(:mods_fixture) { fixture_to_str('academic_commons/indexable/etd_mods.xml') }
      let(:expected_json) { fixture_to_json('academic_commons/indexable/etd_to_solr.json') }

      include_examples 'indexing mods'
    end

    context 'contains multiple parent publication authors' do
      let(:mods_fixture) { fixture_to_str('academic_commons/indexable/parent_publication_names.xml') }
      let(:expected_json) { fixture_to_json('academic_commons/indexable/parent_publication_names.json') }

      include_examples 'indexing mods'
    end

    context 'contains subject titles and subject names' do
      let(:mods_fixture) { fixture_to_str('academic_commons/indexable/subject_names_and_titles.xml') }
      let(:expected_json) { fixture_to_json('academic_commons/indexable/subject_names_and_titles.json') }

      include_examples 'indexing mods'
    end

    context 'contains access restriction' do
      let(:mods_fixture) { fixture_to_str('academic_commons/indexable/access_restriction.xml') }
      let(:expected_json) { fixture_to_json('academic_commons/indexable/access_restriction.json') }

      include_examples 'indexing mods'
    end

    context 'contains multiple series' do
      let(:mods_fixture) { fixture_to_str('academic_commons/indexable/multiple_series.xml') }
      let(:expected_json) { fixture_to_json('academic_commons/indexable/multiple_series.json') }

      include_examples 'indexing mods'
    end
  end
end
