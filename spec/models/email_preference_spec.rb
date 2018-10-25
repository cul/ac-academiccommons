require 'rails_helper'

describe EmailPreference, type: :model do
  context 'when creating multiple records with the same uni' do
    before do
      EmailPreference.create!(uni: 'abc123')
    end

    it 'returns error' do
      expect { EmailPreference.create!(uni: 'abc123') }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  context '.preferred_emails' do
    subject(:preferred_emails) { EmailPreference.preferred_emails(unis) }

    let(:unis) { ['abc123', 'edf123'] }

    before do
      EmailPreference.create!(uni: 'abc123', unsubscribe: true)
      EmailPreference.create!(uni: 'edf123', unsubscribe: false, email: 'e@example.com')
    end

    it 'removes unsubcribed users' do
      expect(preferred_emails).not_to include 'abc123'
    end

    it 'replaces default email with preferred email' do
      expect(preferred_emails['edf123']).to eql 'e@example.com'
    end
  end
end
