require 'rails_helper'

describe EmailPreference, type: :model do
  context 'when creating an invalid record' do
    it 'with missing uni returns error' do
      expect { EmailPreference.create! }.to raise_error ActiveRecord::RecordInvalid
    end

    describe 'with a uni that already has existing preferences' do
      before do
        EmailPreference.create!(uni: 'abc123')
      end

      it 'returns error' do
        expect { EmailPreference.create!(uni: 'abc123') }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  context '.preferred_emails' do
    subject(:preferred_emails) { EmailPreference.preferred_emails(unis) }

    let(:unis) { ['abc123', 'edf123', 'nop123'] }

    before do
      EmailPreference.create!(uni: 'abc123', unsubscribe: true)
      EmailPreference.create!(uni: 'edf123', unsubscribe: false, email: 'e@example.com')
      EmailPreference.create!(uni: 'hji123', unsubscribe: false, email: 'e@example.com')
      EmailPreference.create!(uni: 'lkm123', unsubscribe: true)
      EmailPreference.create!(uni: 'nop123', unsubscribe: false, email: '')
    end

    it 'returns expected hash' do
      expect(preferred_emails).to eql('edf123' => 'e@example.com', 'nop123' => 'nop123@columbia.edu')
    end

    it 'uses default email when email empty' do
      expect(preferred_emails).to include('nop123' => 'nop123@columbia.edu')
    end

    it 'removes unsubcribed users' do
      expect(preferred_emails).not_to include 'abc123'
    end

    it 'replaces default email with preferred email' do
      expect(preferred_emails['edf123']).to eql 'e@example.com'
    end
  end
end
