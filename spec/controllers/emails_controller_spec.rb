require 'rails_helper'

describe EmailsController, type: :controller do
  describe 'GET get_csv_email_form' do
    include_examples 'authorization required' do
      let(:http_request) { get :get_csv_email_form }
    end
  end
end
