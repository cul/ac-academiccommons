shared_context 'mock ldap request' do
  # This file sets up basic mocking for tests that interact with the cul-ldap gem's
  # Cul::LDAP library (primarily AC uses its find_by_uni method).
  #
  # provides doubles: uni : str, cul_ldap : Cul::LDAP, and cul_ldap_entry : Cul::LDAP::Entry
  # mocks calls to initialize and find_by_uni

  let(:uni) { 'tu123' } # Matches the first uid created by User Factory as in "FactoryBot.create(:deposit, :with_user)"

  let(:cul_ldap) do
    instance_double('Cul::LDAP')
  end

  let(:cul_ldap_entry) do
    instance_double(
      'Cul::LDAP::Entry',
      email: 'tu123@columbia.edu', last_name: 'Test', first_name: 'User',
      name: 'Test User', title: 'Librarian', organizational_unit: 'Columbia University Libraries'
    )
  end

  before :each do
    # allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(uni).and_return(cul_ldap_entry)
    allow(Cul::LDAP).to receive(:new).and_return(cul_ldap)
    allow(cul_ldap).to receive(:find_by_uni).and_return(cul_ldap_entry)
  end
end
