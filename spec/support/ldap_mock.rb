shared_context 'mock ldap request' do
  let(:uni) { 'abc123' }

  let(:ldap_request) do
    {
      base: 'o=Columbia University, c=US',
      filter: Net::LDAP::Filter.eq('uid', uni)
    }
  end

  let(:ldap_response) do
    [{
      mail: ['janedoe@columbia.edu'], sn: ['Doe'], givenname: ['Jane'],
      cn: ['Jane Doe'], title: ['Librarian'], ou: ['Columbia University Libraries']
    }]
  end

  before :each do
    allow_any_instance_of(Net::LDAP).to receive(:search).with(ldap_request).and_return(ldap_response)
  end
end
