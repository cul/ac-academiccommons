require 'rails_helper'

describe Deposit, type: :model do
  describe '#mets' do
    shared_examples 'generates expected mets' do
      it 'generates correct mets' do
        expect(Nokogiri::XML(deposit.mets.to_s)).to be_equivalent_to(expected_xml).ignoring_attr_values('CREATEDATE')
      end
    end

    context 'when deposit contains url' do
      subject(:deposit) { FactoryBot.create(:deposit) }

      let(:expected_xml) { fixture_to_xml('deposit_mets', 'mets.xml') }

      include_examples 'generates expected mets'
    end

    context 'when using passing in DOI instead of URL' do
      subject(:deposit) { FactoryBot.create(:deposit, doi: '10.7619/example') }

      let(:expected_xml) { fixture_to_xml('deposit_mets', 'mets_with_doi.xml') }

      include_examples 'generates expected mets'
    end

    context 'when using passing in full DOI URL instead of URL' do
      subject(:deposit) { FactoryBot.create(:deposit, doi: 'https://doi.org/10.7619/example') }

      let(:expected_xml) { fixture_to_xml('deposit_mets', 'mets_with_doi.xml') }

      include_examples 'generates expected mets'
    end

    context 'when deposit contains multiple files' do
      subject(:deposit) do
        d = FactoryBot.create(:deposit)
        d.files.attach(
          io: File.open(fixture('fedora_objs', 'alice_in_wonderland.pdf')),
          filename: 'alice_in_wonderland.pdf'
        )
        d.save
        d
      end

      let(:expected_xml) { fixture_to_xml('deposit_mets', 'mets_with_two_files.xml') }

      include_examples 'generates expected mets'
    end

    context 'when deposit contains no license' do
      subject(:deposit) { FactoryBot.create(:deposit, license: '') }

      let(:expected_xml) { fixture_to_xml('deposit_mets', 'mets_with_no_license.xml') }

      include_examples 'generates expected mets'
    end
  end
end
