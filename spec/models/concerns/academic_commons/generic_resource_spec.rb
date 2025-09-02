# frozen_string_literal: true

require 'rails_helper'
RSpec.describe AcademicCommons::GenericResource do
  let(:obj_doi) { '10.7916/TESTTEST' }
  let(:start_solr_doc) { { 'doi_ssim' => '10.7916/TESTTEST' } }

  # rubocop:disable RSpec/DescribedClass
  let(:including_class) do
    base_class = Class.new do
      attr_accessor :pid, :solr_doc, :datastreams
      def to_solr(doc = {}, _options = {})
        doc.merge(solr_doc || {})
      end
    end
    Class.new(base_class) do
      include AcademicCommons::GenericResource
    end
  end
  let(:fedora_3_pid) { 'actest:1' }
  let(:datastreams) { {} }
  # rubocop:enable RSpec/DescribedClass
  let(:indexable) do
    obj = including_class.new
    obj.pid = fedora_3_pid
    obj.datastreams = datastreams
    obj
  end

  describe '#to_solr' do
    before do
      indexable.solr_doc = start_solr_doc
    end

    it "return the expected hash" do
      expect(indexable.to_solr).to include(id: obj_doi)
    end

    it 'has one :id field' do
      expect(indexable.to_solr.key?(:id)).to be(true)
    end

    it "has no 'id' field" do
      expect(indexable.to_solr.key?('id')).to be(false)
    end

    it 'has an :id field with the doi as value' do
      # Sort of a repeat of 'return the expected hash'
      expect(indexable.to_solr[:id]).to eq(obj_doi)
    end

    context 'no DOI is available' do
      let(:start_solr_doc) { { 'doi_ssim' => '' } }

      it "raises an error" do
        expect { indexable.to_solr }.to raise_error StandardError
      end
    end
  end
end
