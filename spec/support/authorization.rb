# Shared context for mocking administrative user.
shared_context 'mock admin user' do
  before do
    @admin = double(User)
    allow(@admin).to receive(:admin).and_return(true)
    allow(@request.env['warden']).to receive(:authenticate!).and_return(@admin)
    allow(controller).to receive(:current_user).and_return(@admin)
  end
end

# Shared context for mocking a non-administrative user.
shared_context 'mock non-admin user' do
  before do
    @non_admin = double(User)
    allow(@non_admin).to receive(:admin).and_return(false)
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
  context "without being logged in" do
    before do
      #allow(request.env['warden']).to receive(:authenticate!).and_throw(:warden, { :scope => :user })
      allow(controller).to receive(:current_user).and_return(nil)
      http_request
    end

    it "redirects to new_user_session_path" do
      expect(response.status).to eql(302)
      expect(response).to redirect_to new_user_session_url
    end
  end

  context "logged in as a non-admin user" do
    include_context 'mock non-admin user'

    before do
      http_request
    end

    it "fails" do
      expect(response.status).to eql(302)
      expect(response.headers['Location']).to eql(access_denied_url)
    end
  end

  context "logged in as an admin user" do
    include_context 'mock admin user'

    before do
      http_request
    end

    it "succeeds" do
      expect(response.status).to eql(200)
    end
  end
end
