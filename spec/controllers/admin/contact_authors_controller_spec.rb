# frozen_string_literal: true

require 'rails_helper'

describe Admin::ContactAuthorsController, type: :controller, integration: true do
  let(:params) do
    {
      contact_authors_form: {
        send_to: 'all',
        unis: 'testuni',
        subject: 'subject',
        body: 'body'
      }
    }
  end

  describe 'GET new' do
    include_examples 'authorization required' do
      let(:http_request) { get :new }
    end
  end

  describe 'POST create' do
    context 'when html' do
      it_behaves_like 'authorization required', 302 do
        let(:http_request) { post :create, params: params }
      end
    end
  end
end
