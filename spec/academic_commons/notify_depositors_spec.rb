require 'rails_helper'

RSpec.describe AcademicCommons::NotifyDepositors do
  let(:pid) { 'actest:1' }
  let(:uni) { 'abc123' }

  # Mocking solr response for pid actest:1
  let(:solr_response) do
    {
      'response' => {
        'docs' => [
          { "id" => pid, "handle" => "http://dx.doi.org/10.7916/ALICE",
            "title_display" => "Alice's Adventures in Wonderland",
            'author_uni' => [uni, 'xyz123'],
            'free_to_read_start_date' => (Date.today - 1.month).to_s },
        ]
      }
    }.with_indifferent_access
  end

  describe 'get_depositors_to_notify' do
    let(:pid_2) { 'actest:5' }
    let(:item_1) { OpenStruct.new(pid: 'actest:1', authors_uni: ['abc123']) }
    let(:item_2) { OpenStruct.new(pid: pid_2, authors_uni: ['xyz123']) }
    let(:john) { OpenStruct.new(uni: 'xyz123', name: 'John Doe', email: 'xyz123@columbia.edu') }
    let(:jane) { OpenStruct.new(uni: 'abc123', name: 'Jane Doe', email: 'abc123@columbia.edu') }

    before :each do
      allow(AcademicCommons::NotifyDepositors).to receive(:get_item).with(pid).and_return(item_1)
      allow(AcademicCommons::NotifyDepositors).to receive(:get_item).with(pid_2).and_return(item_2)
      allow(AcademicCommons::LDAP).to receive(:find_by_uni).with('xyz123').and_return(john)
      allow(AcademicCommons::LDAP).to receive(:find_by_uni).with('abc123').and_return(jane)
    end

    subject { AcademicCommons::NotifyDepositors.get_depositors_to_notify([pid, pid_2]) }

    it 'returns array with Person objects' do
      expect(subject).to be_an Array
      expect(subject.count).to eql 2
    end

    it 'returns correct person objects' do
      expect(subject).to contain_exactly john, jane
      expect(subject.map(&:items_list).flatten).to contain_exactly item_1, item_2
    end
  end

  describe 'of_new_items' do
    let(:depositors) do
      [
        OpenStruct.new(
          uni: 'abc123',
          email: 'abc123@columbia.edu',
          items_list: [
            OpenStruct.new(id: 'actest:1', handle: "http://dx.doi.org/10.7916/ALICE", title_display: "Alice's Adventures in Wonderland")
          ]
        )
      ]
    end
    before :each do
      Rails.application.config.prod_environment = true  # Pretend to be running in prod.
      allow(AcademicCommons::NotifyDepositors).to receive(:get_depositors_to_notify).with(pid).and_return(depositors)
      AcademicCommons::NotifyDepositors.of_new_items(pid)
    end

    after :each do
      Rails.application.config.prod_environment = false
    end

    it 'sends email' do
      email = ActionMailer::Base.deliveries.pop
      expect(email).not_to eq nil
      expect(email.to).to contain_exactly 'abc123@columbia.edu'
      expect(email.bcc).to include 'example@columbia.edu'
      expect(email.body.to_s).to include 'http://dx.doi.org/10.7916/ALICE'
    end
  end

  describe 'get_item' do
    before :each do
      allow(Blacklight.default_index).to receive(:search)
        .with(any_args).and_return(solr_response)
    end

    subject { AcademicCommons::NotifyDepositors.get_item(pid) }

    its(:pid) { is_expected.to eql pid }
    its(:title) { is_expected.to eql "Alice's Adventures in Wonderland" }
    its(:handle) { is_expected.to eql 'http://dx.doi.org/10.7916/ALICE' }
    its(:authors_uni) { is_expected.to eql ['abc123', 'xyz123']}

    it 'returns with free_to_read_start_date'
  end

  describe 'clean_authors_array' do
    it 'splits strings that contain multiple author unis' do
      cleaned_array = AcademicCommons::NotifyDepositors.clean_authors_array(['abc123, xb1j4', 'cng284'])
      expect(cleaned_array).to eql ['abc123', 'xb1j4', 'cng284']
    end
  end
end
