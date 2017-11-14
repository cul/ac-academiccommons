require 'rails_helper'

RSpec.describe 'DepositorHelper' do
  let(:pid) { 'actest:1' }
  let(:uni) { 'abc123' }

  # Mocking solr response for pid actest:1
  let(:solr_response) do
    {
      'response' => {
        'docs' => [
          { "id" => pid, "handle" => "https://doi.org/10.7916/ALICE",
            "title_display" => "Alice's Adventures in Wonderland",
            'author_uni' => [uni, 'xyz123'],
            'free_to_read_start_date' => (Date.current - 1.month).to_s },
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

end
