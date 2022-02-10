# frozen_string_literal: true

require 'rails_helper'

describe UseAndReproductionHelper, type: :helper do
  let(:cc0) { described_class::CC0 }
  let(:inc) { described_class::IN_COPYRIGHT }
  describe 'use_and_reproduction_display' do
    context "license uri is blank" do
      it "returns nil" do
        expect(helper.use_and_reproduction_display(nil)).to be_nil
        expect(helper.use_and_reproduction_display("")).to be_nil
      end
    end
    context "license uri is for CC0" do
      it "returns a label" do
        expect(helper.use_and_reproduction_display(cc0)).to be_present
      end
    end
    context "license uri is for In-Copyright" do
      it "returns a label" do
        puts helper.use_and_reproduction_display(inc)
        expect(helper.use_and_reproduction_display(inc)).to be_present
      end
    end
    context "is for a reasonable CC-appearing license" do
      it "returns a license label" do
        expect(helper.use_and_reproduction_display('https://creativecommons.org/licenses/by/34.5/')).to include('Attribution 34.5 International')
      end
    end
    context "is for an unreasonable CC-appearing license" do
      it "returns no license label" do
        expect(helper.use_and_reproduction_display('https://creativecommons.org/licenses/by-sa-nd/34.5/')).to be_blank
      end
    end
  end
  describe 'cc_license_attributes' do
    let(:attributes) { helper.cc_license_attributes(license_uri) }
    let(:known_canonical_attributes) do
      {
        uri: 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
        version: '4.0',
        name: 'Attribution-NonCommercial-ShareAlike 4.0 International',
        logos: %i[cc by nc sa]
      }
    end
    context "known values" do
      let(:license_uri) { known_canonical_attributes[:uri] }
      it "canonicalizes for display" do
        expect(attributes).to eql(known_canonical_attributes)
      end
    end
    context "non-canonical known values" do
      let(:license_uri) { 'https://creativecommons.org/licenses/sA-By-nC/4.0/' }
      it "canonicalizes for display" do
        expect(attributes).to eql(known_canonical_attributes)
      end
    end
    context "nonsensical unknown values" do
      let(:contradictory_license_uri) { 'https://creativecommons.org/licenses/by-nd-sa/4.0/' }
      let(:unattributed_license_uri) { 'https://creativecommons.org/licenses/nc-sa/4.0/' }
      it "returns nil" do
        expect(helper.cc_license_attributes(contradictory_license_uri)).to be_nil
        expect(helper.cc_license_attributes(unattributed_license_uri)).to be_nil
      end
    end
    context "sensical unknown values" do
      let(:license_uri) { 'https://creativecommons.org/licenses/by-nc-sa/5.0/' }
      let(:expected_attributes) do
        {
          uri: 'https://creativecommons.org/licenses/by-nc-sa/5.0/',
          version: '5.0',
          name: 'Attribution-NonCommercial-ShareAlike 5.0 International',
          logos: %i[cc by nc sa]
        }
      end
      it "parses for display" do
        expect(attributes).to eql(expected_attributes)
      end
    end
  end
end
