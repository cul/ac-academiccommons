require 'rails_helper'

RSpec.describe 'DepositorHelper' do
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

  describe 'process_indexing' do
    let(:params) do
      {
        commit: "Commit",
        items: 'actest:1',
        overwrite: '1',
        metadata: '1',
        fulltext: '0',
        delete_removed: '0',
        executed_by: 'xyz123'
      }.with_indifferent_access
    end

    let(:reindex_result) do
      { :new_items => ['actest:1'] }
    end

    before :each do
      allow(Blacklight.default_index).to receive(:search).and_return(solr_response)
    end

    # Having trouble testing this method because part of the method runs within
    # its own process.

    # it 'starts reindexing with correct params' do
    #   expect(ACIndexing).to receive(:reindex).with(any_args).and_return(reindex_result)
    #     # .with(hash_including(collections: '', items: ['actest:1'], overwrite: '1',
    #     #    fulltext: '0', matadata: '1', delete_removed: '0', executed_by: 'xyz123'))
    #   helper.process_indexing(params)
    # end

    # it 'sends email for new deposits' do
    #   allow(ACIndexing).to receive(:reindex).with(any_args).and_return(reindex_result)
    #   byebug
    #   helper.process_indexing(params)
    #   email = ActionMailer::Base.deliveries.pop
    #   expect(email).not_to eql nil
    #   expect(email.to).to eql ''
    #   expect(email.bcc).to eql 'ac@columbia.edu'
    #   expect(email.subject).to eql ''
    # end
  end

  describe 'prepare_depositors_to_notify' do
    let(:pid_2) { 'actest:5' }
    let(:item_1) { OpenStruct.new(pid: 'actest:1', authors_uni: ['abc123']) }
    let(:item_2) { OpenStruct.new(pid: pid_2, authors_uni: ['xyz123']) }
    let(:john) { OpenStruct.new(uni: 'xyz123', full_name: 'John Doe', email: 'xyz123@columbia.edu', items_list: []) }
    let(:jane) { OpenStruct.new(uni: 'abc123', full_name: 'Jane Doe', email: 'abc123@columbia.edu', items_list: []) }

    before :each do
      allow(helper).to receive(:get_item).with(pid).and_return(item_1)
      allow(helper).to receive(:get_item).with(pid_2).and_return(item_2)
      allow(helper).to receive(:get_depositor).with('xyz123').and_return(john)
      allow(helper).to receive(:get_depositor).with('abc123').and_return(jane)
    end

    subject { helper.prepare_depositors_to_notify([pid, pid_2]) }

    it 'returns array with Person objects' do
      expect(subject).to be_an Array
      expect(subject.count).to eql 2
    end

    it 'returns correct person objects' do
      expect(subject).to contain_exactly john, jane
      expect(subject.map(&:items_list).flatten).to contain_exactly item_1, item_2
    end
  end

  describe 'notify_depositors_item_added' do
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
      allow(helper).to receive(:prepare_depositors_to_notify).with(pid).and_return(depositors)
      helper.notify_depositors_item_added(pid)
    end

    after :each do
      Rails.application.config.prod_environment = false
    end

    it 'sends email' do
      email = ActionMailer::Base.deliveries.pop
      expect(email).not_to eq nil
      expect(email.to).to contain_exactly 'abc123@columbia.edu'
      expect(email.bcc).to include 'example@columbia.edu'
      expect(email.body.to_s).to have_content 'http://dx.doi.org/10.7916/ALICE'
    end
  end

  describe 'get_item' do
    before :each do
      allow(Blacklight.default_index).to receive(:search)
        .with(any_args).and_return(solr_response)
    end

    subject { helper.get_item(pid) }

    its(:pid) { is_expected.to eql pid }
    its(:title) { is_expected.to eql "Alice's Adventures in Wonderland" }
    its(:handle) { is_expected.to eql 'http://dx.doi.org/10.7916/ALICE' }
    its(:authors_uni) { is_expected.to eql ['abc123', 'xyz123']}

    it 'returns with free_to_read_start_date'
  end

  describe 'get_depositor' do
    include_context 'mock ldap request'

    subject { helper.get_depositor(uni) }

    its(:email)      { is_expected.to eql 'janedoe@columbia.edu'}
    its(:first_name) { is_expected.to eql 'Jane'}
    its(:last_name)  { is_expected.to eql 'Doe'}
    its(:full_name)  { is_expected.to eql 'Jane Doe' }
    its(:uni)        { is_expected.to eql 'abc123' }
  end
end
