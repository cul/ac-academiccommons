require 'rails_helper'

RSpec.describe Cul::Fedora::Item do
  let!(:fedora_config) { Rails.application.config.fedora }
  let!(:pid) { "collection:3" }
  let(:collection_obj) {
    Cul::Fedora::Item.new(server: fedora_config, pid: pid)
  }

  describe "#riquery_for_members" do
    context "when no parameters are present" do
      it 'returns correct query with item pid' do
        expect(
          collection_obj.riquery_for_members
        ).to eq "select $member from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:collection:3>"
      end
    end

    context "when parameters are present" do
      it "returns query with limit and offset" do
        expect(
          collection_obj.riquery_for_members(limit: 100, offset: 0)
        ).to eq "select $member from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:collection:3> order by $member limit 100 offset 0"
      end

      it "returns query with limit" do
        expect(
          collection_obj.riquery_for_members(limit: 100)
        ).to eq "select $member from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:collection:3> order by $member limit 100"
      end

      it "returns query with offset" do
        expect(
          collection_obj.riquery_for_members(offset: 44)
        ).to eq "select $member from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:collection:3> order by $member offset 44"
      end
    end
  end
  describe "#descMetadata_content" do
    let(:item) do
      item = Cul::Fedora::Item.new(server: fedora_config, pid: "actest:1")
    end
    context "MODSMetadata" do
      let(:metadata) do
        meta = Cul::Fedora::Item.new(server: fedora_config, pid: "actest:3")
      end
      before do
        allow(item).to receive(:describedBy).and_return([metadata])
      end
      it do
        expect(metadata).to receive(:datastream).with("CONTENT").and_return("")
        item.descMetadata_content
      end
    end
    context "descMetadata" do
      before do
        allow(item).to receive(:describedBy).and_return([])
      end
      it do
        expect(item).to receive(:datastream).with("descMetadata").and_return("")
        item.descMetadata_content
      end
    end
  end
  describe "#index_for_ac2" do
    let(:item) do
      item = Cul::Fedora::Item.new(server: fedora_config, pid: "actest:1")
      allow(item).to receive(:belongsTo).and_return(['collection:3'])
      item
    end
    let(:mods_fixture) { File.read('spec/fixtures/actest_3/mods.xml') }
    let(:expected_json) { JSON.load File.read('spec/fixtures/actest_1/to_solr.json') }
    context "MODSMetadata" do
      let(:metadata) do
        meta = Cul::Fedora::Item.new(server: fedora_config, pid: "actest:3")
        allow(meta).to receive(:datastream).with("CONTENT").and_return mods_fixture
        meta
      end
      let(:options) { {} }
      before do
        allow(item).to receive(:describedBy).and_return([metadata])
      end
      subject { item.index_for_ac2(options) }
      it do
        expect(subject[:status]).to eql(:success)
        expect(subject[:results]).to eql(expected_json)
      end
    end
    context "descMetadata" do
      let(:options) { {} }
      before do
        allow(item).to receive(:describedBy).and_return([])
        allow(item).to receive(:datastream).with("descMetadata").and_return mods_fixture
      end
      subject { item.index_for_ac2(options) }
      it do
        expect(subject[:status]).to eql(:success)
        expect(subject[:results]).to eql(expected_json)
      end
    end
  end
end
