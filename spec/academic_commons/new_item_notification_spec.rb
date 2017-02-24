require 'rails_helper'

RSpec.describe AcademicCommons::NewItemNotification do
  let(:pid) { 'actest:1' }
  let(:uni) { 'abc123' }

  let(:class_rig) { Class.new { include AcademicCommons::NewItemNotification } }
  let(:dummy_class) { class_rig.new }

  # Mocking solr response for pid actest:1
  let(:solr_response) do
    Blacklight::Solr::Response.new({
      'response' => {
        'docs' => [
          { "id" => pid, "handle" => "http://dx.doi.org/10.7916/ALICE",
            "title_display" => "Alice's Adventures in Wonderland",
            'author_uni' => [uni, 'xyz123'],
            'free_to_read_start_date' => (Date.today - 1.month).to_s },
        ]
      }
    }, {})
  end

  describe 'get_depositors_to_notify' do
    let(:pid_2) { 'actest:5' }
    let(:item_1) { OpenStruct.new(pid: pid, authors_uni: ['abc123'], free_to_read_start_date: Date.today) }
    let(:item_2) { OpenStruct.new(pid: pid_2, authors_uni: ['xyz123'], free_to_read_start_date: Date.tomorrow) }
    let(:john) { OpenStruct.new(uni: 'xyz123', name: 'John Doe', email: 'xyz123@columbia.edu') }
    let(:jane) { OpenStruct.new(uni: 'abc123', name: 'Jane Doe', email: 'abc123@columbia.edu') }

    before :each do
      allow(dummy_class).to receive(:get_item).with(pid).and_return(item_1)
      allow(dummy_class).to receive(:get_item).with(pid_2).and_return(item_2)
      allow(AcademicCommons::LDAP).to receive(:find_by_uni).with('xyz123').and_return(john)
      allow(AcademicCommons::LDAP).to receive(:find_by_uni).with('abc123').and_return(jane)
    end

    subject { dummy_class.get_depositors_to_notify([pid, pid_2]) }

    it 'returns array two objects' do
      expect(subject).to be_an Array
      expect(subject.count).to eql 2
    end

    it 'returns objects with correct person and item details' do
      expect(subject.first.person).to eql jane
      expect(subject.first.new_items).to eql [item_1]
      expect(subject.first.embargoed_items).to eql []
      expect(subject[1].person).to eq john
      expect(subject[1].new_items).to eq []
      expect(subject[1].embargoed_items).to eq [item_2]
    end
  end

  describe '.notify_authors_of_new_items' do
    before :each do
      Rails.application.config.prod_environment = true  # Pretend to be running in prod.
      allow(dummy_class).to receive(:get_depositors_to_notify).with(pid).and_return(depositors)
      dummy_class.notify_authors_of_new_items(pid)
    end

    after :each do
      Rails.application.config.prod_environment = false
    end

    context 'when there are new items, email' do
      let(:depositors) do
        [
          OpenStruct.new(
            person: OpenStruct.new(
              uni: 'abc123',
              email: 'abc123@columbia.edu',
            ),
            new_items: [
              OpenStruct.new(id: 'actest:1', handle: "http://dx.doi.org/10.7916/ALICE", title: "Alice's Adventures in Wonderland")
            ]
          )
        ]
      end

      subject { ActionMailer::Base.deliveries.pop }

      it { is_expected.not_to be nil }
      its(:to)  { is_expected.to contain_exactly 'abc123@columbia.edu' }
      its(:bcc) { is_expected.to include 'example@columbia.edu' }

      it 'body contains correct item details' do
        expect(subject.body.to_s).to include 'http://dx.doi.org/10.7916/ALICE'
        expect(subject.body.to_s).to include CGI::escapeHTML('Alice\'s Adventures in Wonderland')
        puts subject.body.to_s
      end
    end

    context 'when there are new embargoed items' do
      let(:depositors) do
        [
          OpenStruct.new(
            person: OpenStruct.new(
              uni: 'abc123',
              email: 'abc123@columbia.edu',
            ),
            embargoed_items: [
              OpenStruct.new(id: 'actest:1', handle: "http://dx.doi.org/10.7916/ALICE", title: "Alice's Adventures in Wonderland")
            ]
          )
        ]
      end

      subject { ActionMailer::Base.deliveries.pop }

      it { is_expected.not_to be nil }
      its(:to)  { is_expected.to contain_exactly 'abc123@columbia.edu' }
      its(:bcc) { is_expected.to include 'example@columbia.edu' }

      it 'body contains correct item details' do
        body = subject.body.to_s
        expect(body).to include 'The following records are embargoed'
        expect(body).to include 'http://dx.doi.org/10.7916/ALICE'
        expect(body).to include CGI::escapeHTML('Alice\'s Adventures in Wonderland')
      end
    end
  end

  describe 'get_item' do
    before :each do
      allow(Blacklight.default_index).to receive(:find)
        .with(pid, any_args).and_return(solr_response)
    end

    subject { dummy_class.get_item(pid) }

    its(:pid) { is_expected.to eql pid }
    its(:title) { is_expected.to eql "Alice's Adventures in Wonderland" }
    its(:handle) { is_expected.to eql 'http://dx.doi.org/10.7916/ALICE' }
    its(:authors_uni) { is_expected.to eql ['abc123', 'xyz123']}
    its(:free_to_read_start_date) { is_expected.to eql(Date.today - 1.month) }
  end

  describe 'clean_authors_array' do
    it 'splits strings that contain multiple author unis' do
      cleaned_array = dummy_class.clean_authors_array(['abc123, xb1j4', 'cng284'])
      expect(cleaned_array).to eql ['abc123', 'xb1j4', 'cng284']
    end
  end
end
