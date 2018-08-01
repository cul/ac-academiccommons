shared_context 'mock ldap request' do
  let(:uni) { 'abc123' }

  let(:cul_ldap_entry) do
    instance_double(
      'Cul::LDAP::Entry',
      email: 'janedoe@columbia.edu', last_name: 'Doe', first_name: 'Jane',
      name: 'Jane Doe', title: 'Librarian', organizational_unit: 'Columbia University Libraries'
    )
  end

  before :each do
    allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(uni).and_return(cul_ldap_entry)
  end
end
