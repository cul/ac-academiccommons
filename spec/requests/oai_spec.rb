require 'rails_helper'

describe 'OAI endpoint', type: :request do
  describe '/catalog/oai' do
    let(:response_xml) { Nokogiri::XML(response.body) }

    describe '?verb=Identify' do
      let(:expected_xml) { fixture_to_xml('oai_xml', 'identify_response.xml') }

      before do
        get '/catalog/oai?verb=Identify'
      end

      it 'responds with repository information' do
        expect(response_xml).to be_equivalent_to(expected_xml).ignoring_content_of("responseDate")
      end
    end

    describe '?verb=ListRecords&metadataPrefix=oai_dc' do
      let(:expected_xml) { fixture_to_xml('oai_xml', 'list_records_response.xml') }

      before do
        get '/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc'
      end

      it 'responds with one item' do
        expect(response_xml).to be_equivalent_to(expected_xml).ignoring_content_of("responseDate")
      end
    end
  end
end
