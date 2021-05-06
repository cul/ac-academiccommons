require 'rails_helper'
RSpec.describe AcademicCommons::DescMetadata do
  let(:expected_json) { fixture_to_json('desc_metadata/to_solr.json') }
  let(:start_solr_doc) { { 'doi_ssim' => '10.7916/TESTTEST' } }

  # rubocop:disable RSpec/DescribedClass
  let(:indexable) do
    class_rig = Class.new
    class_rig.class_eval do
      include AcademicCommons::DescMetadata

      def belongs_to; end

      def descmetadata_datastream; end

      def pid; end
    end

    indexable = class_rig.new
    allow(indexable).to receive(:pid).and_return('actest:1')

    ds_fixture = ActiveFedora::Datastream.new(indexable, 'test_ds')
    allow(ds_fixture).to receive(:content).and_return mods_fixture
    allow(indexable).to receive(:descmetadata_datastream).and_return ds_fixture

    indexable
  end

  # rubocop:enable RSpec/DescribedClass

  shared_examples 'indexing mods' do
    subject { indexable.index_descmetadata(start_solr_doc) }

    describe '#index_descMetadata' do
      it  { is_expected.to eql(expected_json) }
    end
  end

  # Tests prefixed MODS with joined names. These changes were introduced with the
  # migration to Hyacinth.
  context 'when mods from Hyacinth' do
    let(:mods_fixture) { fixture_to_str('fedora_objs/mods.xml') }

    include_examples 'indexing mods'

    context 'correctly indexes the title' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/non_sort_title.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/non_sort_title.json') }

      include_examples 'indexing mods'
    end

    context 'contains title cased genre value' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/genre_title_case.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/genre_title_case.json') }

      include_examples 'indexing mods'
    end

    context 'contains degree information' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/etd_mods.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/etd_to_solr.json') }

      include_examples 'indexing mods'
    end

    context 'contains multiple parent publication authors' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/parent_publication_names.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/parent_publication_names.json') }

      include_examples 'indexing mods'
    end

    context 'contains related items' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/related_items.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/related_items.json') }

      include_examples 'indexing mods'
    end

    context 'contains subject titles and subject names' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/subject_names_and_titles.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/subject_names_and_titles.json') }

      include_examples 'indexing mods'
    end

    context 'contains access restriction' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/access_restriction.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/access_restriction.json') }

      include_examples 'indexing mods'
    end

    context 'contains multiple series' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/multiple_series.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/multiple_series.json') }

      include_examples 'indexing mods'
    end

    context 'contains multiple languages' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/languages.xml') }
      let(:expected_json) { fixture_to_json('desc_metadata/languages.json') }

      include_examples 'indexing mods'
    end
  end
end
