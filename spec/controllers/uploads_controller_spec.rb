require 'rails_helper'

RSpec.describe UploadsController, type: :controller do
  describe 'POST create' do
    context 'when user logged in ' do
      include_context 'non-admin user for controller'

      let(:deposit) { Deposit.first }

      let(:http_request) do
        file = fixture_file_upload(fixture('test_file.txt'))
        post :create,
             params: {
               deposit: {
                 title: 'Test Deposit',
                 abstract: 'blah blah blah',
                 year: '2008',
                 rights: 'http://rightsstatements.org/vocab/InC/1.0/',
                 creators: [{ first_name: 'Jane', last_name: 'Doe', uni: 'abc123' }],
                 files: [file]
               }
             }
      end

      it 'response is successful' do
        http_request
        expect(response).to have_http_status :success
      end

      it 'enqueues sword deposit job' do
        expect { http_request }.to have_enqueued_job(SwordDepositJob) # with deposit object
      end

      it 'saves deposit properly' do
        http_request
        expect(deposit.title).to eql 'Test Deposit'
        expect(deposit.abstract).to eql 'blah blah blah'
        expect(deposit.year).to eql '2008'
      end

      it 'saves deposit with depositor information' do
        http_request
        expect(deposit.name).to eql 'Test User'
        expect(deposit.uni).to eql 'tu123'
        expect(deposit.authenticated).to be true
        expect(deposit.user).to eql controller.current_user
      end
    end
  end
end
