# frozen_string_literal: true

require 'rails_helper'

describe AcademicCommons do
  let(:default_index) { instance_double(Blacklight::Solr::Repository) }
  let(:blacklight_config) { Blacklight::Configuration.new }

  describe '.search' do
    before do
      allow(Blacklight).to receive(:default_index).and_return(default_index)
    end

    it 'yields SearchParams to the block parameter for basic filters' do
      # d.filter('fedora3_pid_ssi', row['deletePID'])
      expect(default_index).to receive(:search).with(hash_including({ fq: ['fizz:"buzz"'], qt: 'search' }))
      described_class.search { |d| d.filter(:fizz, :buzz) }
    end

    context 'when search_type is :semantic' do
      let(:expected_solr_path) { AcademicCommons::SearchParameters::SEARCH_PATH_SEMANTIC }

      before do
        allow(default_index).to receive(:blacklight_config).and_return(blacklight_config)
      end

      it 'yields SearchParams to the block parameter for solr path' do
        # d.filter('fedora3_pid_ssi', row['deletePID'])
        expect(default_index).to receive(:send_and_receive).with(
          expected_solr_path,
          hash_including({ fq: ['fizz:"buzz"'], qt: nil })
        )
        described_class.search do |d|
          d.filter(:fizz, :buzz)
          d.search_type(:semantic)
        end
      end
    end
  end
end
