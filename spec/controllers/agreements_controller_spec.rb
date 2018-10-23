require 'rails_helper'

describe AgreementsController, type: :controller do
  context 'POST create' do
    let(:agreement) { Agreement.first }

    context 'when user is not logged in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        post :create, params: { agreement: { uni: 'tu123' } }
      end

      it 'redirects to new_user_session_path' do
        expect(response.status).to be 302
        expect(response).to redirect_to new_user_session_url
      end
    end

    context 'when user is logged in' do
      include_context 'non-admin user for controller'

      before do
        post :create,
             params: {
               agreement: {
                 uni: 'tu123',
                 agreement_version: Agreement::LATEST_AGREEMENT_VERSION,
                 name: 'Test User',
                 email: 'tu123@example.com',
                 accepted_agreement: true
               }
             }
      end

      it 'creates correct agreement record' do
        expect(agreement.uni).to eql 'tu123'
        expect(agreement.name).to eql 'Test User'
        expect(agreement.email).to eql 'tu123@example.com'
      end

      it 'sends email' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.subject).to eql 'Academic Commons Author Agreement Accepted'
        expect(email.body).to include 'Accepted Author Agreement'
      end

      it 'if missing accepting agreement does not create record'
    end

    context 'when valid token is provided and user is not logged in' do
      before do
        post :create,
             params: {
               agreement: {
                 uni: nil,
                 agreement_version: Agreement::LATEST_AGREEMENT_VERSION,
                 name: 'Test User with Token',
                 email: 'tu123@columbia.edu',
                 token: Rails.application.message_verifier(:agreement).generate(['tu123@columbia.edu', nil, Agreement::LATEST_AGREEMENT_VERSION]),
                 accepted_agreement: true
               }
             }
      end

      it 'creates correct agreement record' do
        expect(agreement.uni).to be nil
        expect(agreement.name).to eql 'Test User with Token'
        expect(agreement.email).to eql 'tu123@columbia.edu'
      end

      it 'send email' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.subject).to eql 'Academic Commons Author Agreement Accepted'
        expect(email.body).to include 'Test User with Token'
      end
    end

    context 'when invalid token is provided and user is not logged in' do
      let(:http_request) do
        post :create,
             params: {
               agreement: {
                 uni: nil,
                 agreement_version: Agreement::LATEST_AGREEMENT_VERSION,
                 name: 'Test User with Token',
                 email: 'tu123@columbia.edu',
                 token: 'dsfasldfkjsldfk',
                 accepted_agreement: true
               }
             }
      end

      it 'raises error' do
        expect { http_request }.to raise_error ActiveSupport::MessageVerifier::InvalidSignature
      end
    end
  end
end
