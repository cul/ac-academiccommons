shared_context 'mock ldap request' do
  let(:uni) { 'tu123' } # Matches the first uid created by User Factory as in "FactoryBot.create(:deposit, :with_user)"

  let(:cul_ldap_entry) do
    instance_double(
      'Cul::LDAP::Entry',
      email: 'tu123@columbia.edu', last_name: 'Test', first_name: 'User',
      name: 'Test User', title: 'Librarian', organizational_unit: 'Columbia University Libraries'
    )
  end

  before :each do
    allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(uni).and_return(cul_ldap_entry)
  end
end
