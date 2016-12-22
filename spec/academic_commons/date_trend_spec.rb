require 'rails_helper'


describe AcademicCommons::DateTrend do
  let(:solr_fixture) do
    erb = File.read('spec/fixtures/academic_commons/date_trend/solr_response.json.erb')
    now = Time.now
    json = ERB.new(erb).result binding
    JSON.parse(json)
  end
  let(:class_uri) { "info:fedora/cul:TestRig" }
  let(:date_field) { 'some_date_field' }
  subject { described_class.new(date_field, model) }
  let(:model) do
    model = Class.new do
      def self.to_class_uri; end
    end
    allow(model).to receive(:to_class_uri).and_return(class_uri)
    model
  end
  describe '#search_params' do
    context 'an ActiveFedora model' do
      it do
        expect(subject.search_params).to include(
          fq: ["has_model_ssim:\"#{class_uri}\""],
          :"facet.range" => date_field
        )
      end
    end
    context 'no ActiveFedora model' do
      let(:model) { nil }
      it do
        expect(subject.search_params).to include(fq: [], :"facet.range" => date_field)
      end
    end
  end
  describe '#counts' do
    let(:date_field) { 'system_modified_dtsi' }
    let(:default_index) { double('Mock RSolr') }
    let(:connection) { double('Connection') }
    before do
      allow(Blacklight).to receive(:default_index)
        .and_return(default_index)
      allow(default_index).to receive(:connection)
        .and_return(connection)
      allow(connection).to receive(:get).and_return(solr_fixture)
    end
    it  { expect(subject.counts).to eql(last_month: 13779, last_year: 40047,total: 116471) }
  end
end
