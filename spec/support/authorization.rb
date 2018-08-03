# Shared context for creating administrative user.
shared_context 'admin user' do
  before do
    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('ta123').twice.and_return(nil)
    @admin = User.create!(uid: 'ta123', first_name: 'Test', last_name: 'Admin', email: 'ta123@columbia.edu', role: User::ADMIN)
    # allow(@admin).to receive(:admin?).and_return(true)
    allow(@request.env['warden']).to receive(:authenticate!).and_return(@admin)
    allow(controller).to receive(:current_user).and_return(@admin)
  end
end

# Shared context for creating a non-administrative user.
shared_context 'non-admin user' do
  before do
    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('tu123').twice.and_return(nil)
    @non_admin = User.create!(uid: 'tu123', first_name: 'Test', last_name: 'User', email: 'tu123@columbia.edu')
    # allow(@non_admin).to receive(:admin?).and_return(false)
    allow(@request.env['warden']).to receive(:authenticate!).and_return(@non_admin)
    allow(controller).to receive(:current_user).and_return(@non_admin)
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
shared_examples 'authorization required' do
  context 'without being logged in' do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
      http_request
    end

    it 'redirects to new_user_session_path' do
      expect(response.status).to be 302
      expect(response).to redirect_to new_user_session_url
    end
  end

  context 'logged in as a non-admin user' do
    include_context 'non-admin user'

    # In order to check status code, etc, need to create request specs.
    it 'fails' do
      expect { http_request }.to raise_error CanCan::AccessDenied
    end
  end

  context 'logged in as an admin user' do
    include_context 'admin user'

    before do
      http_request
    end

    it 'succeeds' do
      expect(response.status).to be 200
    end
  end
end
