# Shared context for creating non-administrative user in features specs.
shared_context 'non-admin user for feature' do
  before do
    OmniAuth.config.test_mode = true
    Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('tu123').and_return(nil)
    # for tests where we need to login as an admin user to test a non-admin action
    allow(ldap).to receive(:find_by_uni).with('ta123').and_return(nil)
    login_as FactoryBot.create(:user), scope: :user
  end
end

# Shared context for creating administrative user in features specs.
shared_context 'admin user for feature' do |additional_unis|
  before do
    OmniAuth.config.test_mode = true
    Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('ta123').and_return(nil)
    Array.wrap(additional_unis).compact.each { |uni| allow(ldap).to receive(:find_by_uni).with(uni).and_return(nil) }
    login_as FactoryBot.create(:admin), scope: :user
  end
end
