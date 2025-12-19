# frozen_string_literal: true

require 'rails_helper'

describe 'rake ac:delete_stale_pending_works', type: :task do
  context 'when a deposit with no hyacinth identifier' do
    puts 'inside context'
    let!(:deposit_fresh) { FactoryBot.create(:deposit, :with_user) }
    let!(:deposit_stale) do
      FactoryBot.create(:deposit, :with_user, created_at: 7.months.ago)
    end

    describe 'that is less than 6 months old' do
      it 'does not delete the deposit' do
        puts 'inside pending works test!!'
        task.execute
        puts Deposit
        expect(Deposit.exists?(deposit_fresh.id)).to be true
      end
    end

    describe 'that is over 6 months old' do
      it 'deletes the deposit' do
        task.execute
        expect { deposit_stale.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context 'when a deposit with an identifier that is unindexed' do
    let(:empty_response) { wrap_solr_response_data('response' => { 'docs' => [] }) }
    let!(:deposit_fresh) do
      FactoryBot.create(:deposit, :with_user, hyacinth_identifier: 'unindexed')
    end
    let!(:deposit_stale) do
      FactoryBot.create(:deposit, :with_user, created_at: 7.months.ago, hyacinth_identifier: 'unindexed')
    end

    before do
      allow(AcademicCommons).to receive(:search).and_return(empty_response)
    end

    describe 'and is less than 6 months old' do
      it 'does not delete the deposit' do
        task.execute
        expect(Deposit.exists?(deposit_fresh.id)).to be true
      end
    end

    describe 'and is over 6 months old' do
      it 'deletes the deposit' do
        task.execute
        expect { deposit_stale.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context 'when a deposit with an identifier that is indexed' do
    let(:solr_response) do
      wrap_solr_response_data(
        'response' => {
          'docs' => [
            { 'id' => '10.7916/TESTDOC10', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
              'cul_doi_ssi' => '10.7916/TESTDOC10', 'fedora3_pid_ssi' => 'actest:10', 'genre_ssim' => '',
              'publisher_doi_ssi' => '', 'free_to_read_start_date_ssi' => Date.current.tomorrow.strftime('%Y-%m-%d') }
          ]
        }
      )
    end
    let!(:deposit_fresh) do
      FactoryBot.create(:deposit, :with_user, hyacinth_identifier: 'actest:10')
    end
    let!(:deposit_stale) do
      FactoryBot.create(:deposit, :with_user, created_at: 7.months.ago, hyacinth_identifier: 'actest:10')
    end

    before do
      allow(AcademicCommons).to receive(:search).and_return(solr_response)
    end

    describe 'and is less than 6 months old' do
      it 'does not delete the deposit' do
        task.execute
        expect(Deposit.exists?(deposit_fresh.id)).to be true
      end
    end

    describe 'and is over 6 months old' do
      it 'does not delete the deposit' do
        task.execute
        expect(Deposit.exists?(deposit_stale.id)).to be true
      end
    end
  end
end
