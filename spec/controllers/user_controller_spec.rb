require 'rails_helper'

describe UserController, type: :controller do
  describe 'GET unsubscribe_monthly' do
    let(:uni) { 'abc123' }

    context 'does not add email preference' do
      it 'when author missing' do
        get :unsubscribe_monthly, params: { chk: 'foo' }
        expect(EmailPreference.count).to eq 0
      end

      it 'when chk missing' do
        get :unsubscribe_monthly, params: { author_id: 'foo' }
        expect(EmailPreference.count).to eq 0
      end

      it 'when chk and author missing' do
        get :unsubscribe_monthly
        expect(EmailPreference.count).to eq 0
      end
    end

    context 'when chk param is correctly signed' do
      before do
        get :unsubscribe_monthly, params: { author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate(uni) }
      end

      it 'creates email preference' do
        expect(EmailPreference.count).to eq 1
      end

      it 'unsubscribes user' do
        expect(EmailPreference.first.author).to eq uni
        expect(EmailPreference.first.monthly_opt_out).to be true
      end

      it 'changes email preference' do
        EmailPreference.first.update!(monthly_opt_out: false)
        get :unsubscribe_monthly, params: { author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate(uni) }
        expect(EmailPreference.first.monthly_opt_out).to be true
      end
    end

    context 'when check param is not correctly signed' do
      before do
        get :unsubscribe_monthly, params: { author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate('abc') }
      end

      it 'does not unsubscribe user' do
        expect(EmailPreference.count).to eq 0
      end
    end
  end
end
