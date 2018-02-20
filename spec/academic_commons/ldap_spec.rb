require 'rails_helper'

RSpec.describe AcademicCommons::LDAP do
  describe '.find_by_uni' do
    include_context 'mock ldap request'
    subject { AcademicCommons::LDAP.find_by_uni(uni) }

    context 'when all fields available returns' do
      its(:name)       { is_expected.to eql 'Jane Doe' }
      its(:email)      { is_expected.to eql 'janedoe@columbia.edu' }
      its(:first_name) { is_expected.to eql 'Jane' }
      its(:last_name)  { is_expected.to eql 'Doe' }
      its(:uni)        { is_expected.to eql uni }
      its(:title)      { is_expected.to eql 'Librarian' }
      its(:organizational_unit) { is_expected.to eql 'Columbia University Libraries' }
    end

    context 'when ldap does not have record for uni' do
      let(:ldap_response) { [] }

      its(:name)       { is_expected.to be nil }
      its(:email)      { is_expected.to eql "#{uni}@columbia.edu" }
      its(:first_name) { is_expected.to be nil }
      its(:last_name)  { is_expected.to be nil }
      its(:uni)        { is_expected.to be uni }
      its(:title)      { is_expected.to be nil }
      its(:organizational_unit) { is_expected.to be nil }
    end

    context 'when ldap does not have email' do #has names, but not email
      let(:ldap_response) { [{ sn: 'Doe', givenname: 'Jane', cn: 'Jane Doe' }] }

      its(:name)       { is_expected.to eql 'Jane Doe' }
      its(:email)      { is_expected.to eql "#{uni}@columbia.edu" }
      its(:first_name) { is_expected.to eql 'Jane' }
      its(:last_name)  { is_expected.to eql 'Doe' }
      its(:uni)        { is_expected.to eql uni }
      its(:title)      { is_expected.to eql '' }
      its(:organizational_unit) { is_expected.to eql '' }
    end
  end
end
