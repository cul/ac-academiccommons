shared_context 'mock ldap request' do
  let(:uid) { 'abc123' }

  let(:ldap_request) do
    {
      :base => "o=Columbia University, c=US",
      :filter => Net::LDAP::Filter.eq("uid", uid)
    }
  end

  let(:ldap_response) do
    [{ :mail => 'abc123@columbia.edu', :sn => 'Doe', :givenname => 'Jane' }]
  end

  before :each do
    allow_any_instance_of(Net::LDAP).to receive(:search).with(ldap_request).and_return(ldap_response)
  end
end
