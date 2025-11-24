require 'rails_helper'
RSpec.describe AcademicCommons::DescMetadata do
  # Replace the 'id' key with an ':id' key
  def fixture_to_json_symbol_id(file)
    json = fixture_to_json(file)
    doi = json['id']
    json[:id] = doi
    json.delete('id')
    json
  end

  let(:mock_vector_embedding_value) do
    fixture_to_json('desc_metadata/mock_vector_embedding_value_string-research.json')
  end
  let(:searchable_text_vector768i_key_value_pair) do
    { 'searchable_text_vector768i' => mock_vector_embedding_value }
  end
  let(:expected_json) do
    fixture_to_json_symbol_id('desc_metadata/to_solr.json').merge(
      searchable_text_vector768i_key_value_pair
    )
  end
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

    before do
      allow(EmbeddingService::Endpoint).to receive(:generate_vector_embedding).and_return(mock_vector_embedding_value)
    end

    describe '#index_descMetadata' do
      it {
        expect(subject).to eql(expected_json)
      }

      it 'has one :id field' do
        expect(subject.key?(:id)).to be(true)
      end

      it "has no 'id' field" do
        expect(subject.key?('id')).to be(false)
      end

      it 'has an :id field with the doi as value' do
        expect(subject[:id]).to eq(start_solr_doc['doi_ssim'])
      end

      context 'no DOI is available' do
        let(:start_solr_doc) { { 'doi_ssim' => '' } }
        it "raises an error" do
          expect { indexable.index_descmetadata(start_solr_doc) }.to raise_error StandardError
        end
      end
    end
  end

  # Tests prefixed MODS with joined names. These changes were introduced with the
  # migration to Hyacinth.
  context 'when mods from Hyacinth' do
    let(:mods_fixture) { fixture_to_str('fedora_objs/mods.xml') }

    include_examples 'indexing mods'

    context 'correctly indexes the title' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/non_sort_title.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/non_sort_title.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains title cased genre value' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/genre_title_case.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/genre_title_case.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains mapped genre value' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/genre_mapping.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/genre_mapping.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains degree information' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/etd_mods.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/etd_to_solr.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains multiple parent publication authors' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/parent_publication_names.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/parent_publication_names.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains related items' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/related_items.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/related_items.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains subject titles and subject names' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/subject_names_and_titles.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/subject_names_and_titles.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains access restriction' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/access_restriction.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/access_restriction.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end

    context 'contains multiple series' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/multiple_series.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/multiple_series.json').merge(searchable_text_vector768i_key_value_pair)
      end

      include_examples 'indexing mods'
    end

    context 'contains multiple languages' do
      let(:mods_fixture) { fixture_to_str('desc_metadata/languages.xml') }
      let(:expected_json) do
        fixture_to_json_symbol_id('desc_metadata/languages.json').merge(
          searchable_text_vector768i_key_value_pair
        )
      end

      include_examples 'indexing mods'
    end
  end
end
