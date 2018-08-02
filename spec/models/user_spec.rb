require 'rails_helper'

describe User, type: :model do
  context '#set_personal_info_via_ldap' do
    let(:ldap) { instance_double(Cul::LDAP) }
    let(:uni)  { 'abc123' }
    let(:cul_ldap_entry) do
      instance_double('Cul::LDAP::Entry', email: 'abc123@columbia.edu', first_name: 'Jane Doe', last_name: 'Doe')
    end
    let(:user) { User.new(uid: uni) }

    before do
      allow(Cul::LDAP).to receive(:new).and_return(ldap)
    end

    context 'if creating a new record' do
      before do
        allow(ldap).to receive(:find_by_uni).with(uni).and_raise(StandardError)
      end

      it 'raises error if ldap query fails' do
        expect { uni.set_personal_info_via_ldap }.to raise_error StandardError
      end
    end

    context 'if updating a record' do
      before do
        allow(ldap).to receive(:find_by_uni).with(uni).twice.and_return(cul_ldap_entry)
        user.save
      end

      it 'does not raise an error if ldap query fails' do
        allow(ldap).to receive(:find_by_uni).with(uni).and_raise(StandardError)

        expect { user.set_personal_info_via_ldap }.not_to raise_error
      end
    end
  end
end
