require 'rails_helper'

describe Deposit, type: :model do
  it 'saves deposit with valid attributes' do
    deposit = FactoryBot.build(:deposit)
    expect(deposit).to be_valid
    expect { deposit.save! }.not_to raise_error
  end

  it 'saves the metadata store attributes' do # rubocop:disable RSpec/MultipleExpectations
    deposit = FactoryBot.create(:deposit)
    deposit.save!
    expect(deposit.metadata).to be_present
    expect(deposit.title).to eq 'Test Deposit'
    expect(deposit.abstract).to eq 'foobar'
    expect(deposit.year).to eq '2018'
    expect(deposit.doi).to eq 'https://www.example.com'
    expect(deposit.license).to eq 'https://creativecommons.org/licenses/by/4.0/'
    expect(deposit.rights).to eq 'http://rightsstatements.org/vocab/InC/1.0/'
    expect(deposit.notes).to eq 'This deposit is just for testing purposes.'
    expect(deposit.creators).to eq [
      { 'first_name' => 'Jane', 'last_name' => 'Doe', 'uni' => 'abc123' },
      { 'first_name' => 'John', 'last_name' => 'Doe', 'uni' => '' }
    ]
  end

  describe 'validations' do
    describe 'should be invalid' do
      it 'without a title' do
        deposit = FactoryBot.build(:deposit, title: nil)
        expect(deposit).not_to be_valid
      end

      it 'without an abstract' do
        deposit = FactoryBot.build(:deposit, abstract: nil)
        expect(deposit).not_to be_valid
      end

      it 'without a year' do
        deposit = FactoryBot.build(:deposit, year: nil)
        expect(deposit).not_to be_valid
      end

      it 'without rights' do
        deposit = FactoryBot.build(:deposit, rights: nil)
        expect(deposit).not_to be_valid
      end

      it 'without uploaded files' do
        deposit = FactoryBot.build(:deposit).tap do |dep|
          dep.files.detach # files added by factory in after(:build) hook -- detach them here
        end
        expect(deposit).not_to be_valid
      end

      it 'without previously_published value' do
        deposit = FactoryBot.build(:deposit, previously_published: nil)
        expect(deposit).not_to be_valid
      end

      it 'without current_student value' do
        deposit = FactoryBot.build(:deposit, current_student: nil)
        expect(deposit).not_to be_valid
      end

      it 'with invalid rights' do
        deposit = FactoryBot.build(:deposit, rights: 'invalid')
        expect(deposit).not_to be_valid
      end

      it 'with invalid license' do
        deposit = FactoryBot.build(:deposit, license: 'invalid')
        expect(deposit).not_to be_valid
      end

      describe 'when current_student is true' do
        it 'without degree_program' do
          deposit = FactoryBot.build(:deposit, current_student: true, degree_program: nil)
          expect(deposit).not_to be_valid
        end

        it 'without academic_advisor' do
          deposit = FactoryBot.build(:deposit, current_student: true, academic_advisor: nil)
          expect(deposit).not_to be_valid
        end

        it 'without thesis_or_dissertation' do
          deposit = FactoryBot.build(:deposit, current_student: true, thesis_or_dissertation: nil)
          expect(deposit).not_to be_valid
        end
      end
    end
  end

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
