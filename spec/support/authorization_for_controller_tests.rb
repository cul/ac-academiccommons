# Shared context for creating administrative user in controller specs.
shared_context 'admin user for controller' do
  before do
    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('ta123').twice.and_return(nil)
    admin = FactoryBot.create(:admin)
    allow(request.env['warden']).to receive(:authenticate!).and_return(admin)
    allow(controller).to receive(:current_user).and_return(admin)
  end
end

# Shared context for creating a non-administrative user in controller specs
shared_context 'non-admin user for controller' do
  before do
    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('tu123').twice.and_return(nil)
    non_admin = FactoryBot.create(:user)
    allow(request.env['warden']).to receive(:authenticate!).and_return(non_admin)
    allow(controller).to receive(:current_user).and_return(non_admin)
  end
end

# Shared example to check that a route requires authentication and
# authorization. When including this example a let statement must be provided
# with the http_request.
#
# @example Usage
#   include_examples 'authorization required' do
#     let(:http_request) { get :index }
#   end
shared_examples 'authorization required' do |success_status|
  context 'without being logged in' do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
      http_request
    end

    # rubocop:disable RSpec/ExampleLength
    it 'returns correct status code based on content type' do
      if response.content_type == 'application/json'
        expect(response.status).to eq(403)
      else
        expect(response.status).to eq(302)
        expect(response).to redirect_to new_user_session_url
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength

  context 'logged in as a non-admin user' do
    include_context 'non-admin user for controller'

    # In order to check status code, etc, need to create request specs.
    it 'fails' do
      expect { http_request }.to raise_error CanCan::AccessDenied
    end
  end

  context 'logged in as an admin user' do
    include_context 'admin user for controller'
    let(:expected_status) { success_status || 200 }
    before do
      http_request
    end

    it 'succeeds' do
      expect(response.status).to eq(expected_status)
    end
  end
end
