require 'spec_helper'

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
end
