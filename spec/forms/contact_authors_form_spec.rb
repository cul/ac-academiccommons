# frozen_string_literal: true

require 'rails_helper'

describe ContactAuthorsForm, type: :model do
  subject(:email) { ActionMailer::Base.deliveries.pop }

  let(:test_ids) { 'abc123, def456' }
  let(:test_preferred_emails) { ['abc123@columbia.edu', 'def456@columbia.edu'] }

  describe '#valid_unis_format?' do
    let(:params) do
      {
        send_to: 'specific_authors', unis: 'abc123, def456', subject: 'test subject', body: 'test body'
      }
    end

    context 'with well formated unis' do
      it 'returns without adding errors' do # rubocop:disable RSpec/MultipleExpectations
        form = described_class.new(params)
        expect(form).to be_valid
        expect(form.errors[:unis]).to be_empty
      end
    end

    context 'with bad-formatted unis field' do
      it 'returns false if a empty item in unis list' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        test_params = {
          send_to: 'specific_authors', unis: 'abc123,,, def456', subject: 'test subject', body: 'test body'
        }
        form = described_class.new(test_params)
        expect(form).not_to be_valid
        expect(form.errors[:unis]).to include('list must be properly formatted')
      end

      it 'returns false if whitespace in uni' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        test_params = {
          send_to: 'specific_authors', unis: 'abc123 def456', subject: 'test subject', body: 'test body'
        }
        form = described_class.new(test_params)
        expect(form).not_to be_valid
        expect(form.errors[:unis]).to include('list must be properly formatted')
      end
    end
  end

  context 'when contacting specific authors' do
    let(:params) do
      {
        send_to: 'specific_authors', unis: 'abc123, def456', subject: 'test subject', body: 'test body'
      }
    end

    describe '#valid_unis_format?' do
      it 'returns without adding errors with well formated unis' do # rubocop:disable RSpec/MultipleExpectations
        form = described_class.new(params)
        expect(form).to be_valid
        expect(form.errors[:unis]).to be_empty
      end

      it 'returns false if a empty item in unis list' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        test_params = {
          send_to: 'specific_authors', unis: 'abc123,,, def456', subject: 'test subject', body: 'test body'
        }
        form = described_class.new(test_params)
        expect(form).not_to be_valid
        expect(form.errors[:unis]).to include('list must be properly formatted')
      end

      it 'returns false if whitespace in uni' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        test_params = {
          send_to: 'specific_authors', unis: 'abc123 def456', subject: 'test subject', body: 'test body'
        }
        form = described_class.new(test_params)
        expect(form).not_to be_valid
        expect(form.errors[:unis]).to include('list must be properly formatted')
      end
    end

    describe '#recipients' do
      before do
        described_class.new(params).recipients
      end

      it 'does not retrieve all author unis' do
        allow(AcademicCommons).to receive(:all_author_unis)
        expect(AcademicCommons).not_to have_received(:all_author_unis) # rubocop:disable RSpec/MessageSpies
      end
    end
  end

  context 'when contacting all authors' do
    let(:params) do
      {
        send_to: 'all', unis: '', subject: 'test subject', body: 'test body'
      }
    end

    before do
      allow(AcademicCommons).to receive(:all_author_unis).and_return(test_ids)
      allow(EmailPreference).to receive_message_chain(:preferred_emails, :values).and_return(test_preferred_emails) # rubocop:disable RSpec/MessageChain
    end

    describe '#send_emails' do
      before do
        described_class.new(params).send_emails
      end

      it 'sends to correct author' do # rubocop:disable RSpec/MultipleExpectations
        expect(email.bcc).to include 'abc123@columbia.edu'
        expect(email.bcc).to include 'def456@columbia.edu'
      end

      it 'sends with expected subject' do
        expect(email.subject).to eql 'test subject'
      end

      it 'returns false if invalid form fields' do
        test_missing_params = { send_to: '', unis: '', subject: '', body: '' }
        test_instance = described_class.new(test_missing_params)
        expect(test_instance.send_emails).to be(false)
      end

      it 'returns false if an error is raised' do
        allow(UserMailer).to receive(:contact_authors).and_raise(StandardError)
        test_instance = described_class.new(params)
        expect(test_instance.send_emails).to be(false)
      end
    end

    describe '#recipients' do
      before do
        described_class.new(params).recipients
      end

      it 'retrieves all author unis from academic commons' do
        expect(AcademicCommons).to have_received(:all_author_unis) # rubocop:disable RSpec/MessageSpies
      end
    end
  end
end
