require 'rails_helper'

describe Deposit, type: :model do
  describe '#mets' do
    subject(:deposit) { FactoryBot.create(:deposit) }

    let(:expected_xml) { fixture_to_xml('deposit_mets', 'mets.xml') }

    it 'generates correct mets' do
      expect(Nokogiri::XML(deposit.mets.to_s)).to be_equivalent_to(expected_xml).ignoring_content_of('metsHdr')
    end

    context 'when using passing in DOI instead of URL' do
      subject(:deposit) { FactoryBot.create(:deposit, doi: '10.7619/example') }

      it 'generates correct mets'
    end

    context 'when using passing in full DOI URL instead of URL' do
      subject(:deposit) { FactoryBot.create(:deposit, doi: 'https://doi.org/10.7619/example') }

      it 'generates correct mets'
    end

    context 'when deposit contains multiple files'
  end
end
