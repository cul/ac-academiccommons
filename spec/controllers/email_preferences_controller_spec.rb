require 'rails_helper'

describe EmailPreferencesController, :type => :controller do
  let(:deposit)   { EmailPreference.create(author: 'John Doe', monthly_opt_out: false, email: 'john.doe@example.com') }

  describe 'GET index' do
    include_examples 'authorization required' do
      let(:request) { get :index }
    end
  end

  describe 'GET show' do
    include_examples 'authorization required' do
      let(:request) { get :show, id: deposit.id }
    end
  end

  describe 'GET new' do
    include_examples 'authorization required' do
      let(:request) { get :new }
    end
  end

  describe 'POST create' do
    include_examples 'authorization required' do
      let(:request) {
        post :create, email_preference: { author: 'John Doe', monthly_opt_out: true, email: 'john.doe@example.com' }
      }
    end
  end

  describe 'GET edit' do
    include_examples 'authorization required' do
      let(:request) { get :edit, id: deposit.id}
    end
  end

  describe 'PUT update' do
    include_examples 'authorization required' do
      let(:request) { put :update, id: deposit.id }
    end
  end

  describe 'DELETE destroy' do
    include_examples 'authorization required' do
      let(:request) { delete :destroy, id: deposit.id }
    end
  end
end
