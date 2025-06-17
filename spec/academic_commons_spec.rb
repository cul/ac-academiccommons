# frozen_string_literal: true

require 'rails_helper'

describe AcademicCommons do
  let(:default_index) { instance_double(Blacklight::Solr::Repository) }

  describe '.search' do
    before do
      allow(Blacklight).to receive(:default_index).and_return(default_index)
    end

    it 'yields SearchParams to the block parameter' do
      # d.filter('fedora3_pid_ssi', row['deletePID'])
      expect(default_index).to receive(:search).with(hash_including({ fq: ['fizz:"buzz"'] }))
      described_class.search { |d| d.filter(:fizz, :buzz) }
    end
  end
end
