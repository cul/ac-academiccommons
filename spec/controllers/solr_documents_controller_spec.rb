require 'rails_helper'

describe SolrDocumentsController, :type => :controller do
  shared_context 'good api key' do
   let(:api_key) do
     key = Rails.application.secrets.index_api_key
     ActionController::HttpAuthentication::Token.encode_credentials(key)
   end
  end

  shared_context 'bad api key' do
    let(:api_key) do
      ActionController::HttpAuthentication::Token.encode_credentials('badtoken')
    end
  end

  shared_context 'mock api key' do
    before do
      @original_creds = Rails.application.secrets.index_api_key
      Rails.application.secrets.index_api_key = 'goodtoken'
      request.env['HTTP_AUTHORIZATION'] = api_key
      allow(ActiveFedora::Base).to receive(:find).with('baad:id').and_raise(ActiveFedora::ObjectNotFoundError)
    end

    after do
      Rails.application.secrets.index_api_key = @original_creds
    end

    let(:mock_object) do
      double(ActiveFedora::Base)
    end
  end

  describe '#update' do
    include_context 'mock api key'
    subject do
      put :update, params
      response.status
    end
    context 'no api key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      include_context 'bad api key'

      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api key' do
      include_context 'good api key'
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(404) }
      end
      context 'good doc id' do
        let(:mock_object) do
          ContentAggregator.new
        end
        let(:params) { { id: 'good:id' } }
        before do
          allow(ActiveFedora::Base).to receive(:find).with('good:id').and_return(mock_object)
          allow(mock_object).to receive(:pid).and_return('good:id')
          allow(mock_object).to receive(:to_solr).and_return(Hash.new)
          expect(ActiveFedora::SolrService).to receive(:add).with(Hash.new)
          expect(controller).to receive(:notify_authors_of_new_item)
        end
        it do
          expect(subject).to eql(200)
        end
      end
    end
  end

  describe '#destroy' do
    include_context 'mock api key'

    let(:rsolr) { double('RSolr') }
    #TODO: Determine if RSolr signals a missing id on delete
    let(:bad_id_response) do
      {"responseHeader"=>{"status"=>0, "QTime"=>41}}
    end
    let(:good_id_response) do
      {"responseHeader"=>{"status"=>0, "QTime"=>41}}
    end
    before do
      allow(controller).to receive(:rsolr).and_return(rsolr)
    end
    subject do
      delete :destroy, params
      response.status
    end
    context 'no api key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      include_context 'bad api key'
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api key' do
      include_context 'good api key'
      before do
        allow(rsolr).to receive(:delete_by_id).with('baad:id').and_return(bad_id_response)
        allow(rsolr).to receive(:delete_by_id).with('good:id').and_return(good_id_response)
        allow(rsolr).to receive(:commit)
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(200) }
      end
      context 'good doc id' do
        let(:params) { { id: 'good:id' } }
        it { is_expected.to eql(200) }
      end
    end
  end

  describe '#notify_authors_of_new_item' do
    let(:author_one) { 'abc123' }
    let(:author_two) { 'xyz123' }
    let(:email_author_one) { "#{author_one}@columbia.edu" }
    let(:email_author_two) { "#{author_two}@columbia.edu" }
    let(:doi) { "10.7916/ALICE" }
    let(:entry_for_author_one) {
      double('ldap_author_one', email: email_author_one, name: 'Author One' )
    }
    let(:entry_for_author_two) {
      double('ldap_author_two', email: email_author_two, name: 'Author Two' )
    }

    let(:sent_to) { ActionMailer::Base.deliveries.map(&:to).flatten }

    before :each do
      Rails.application.config.prod_environment = true  # Pretend to be running in prod.
      allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(author_one).and_return(entry_for_author_one)
      allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(author_two).and_return(entry_for_author_two)
    end

    after :each do
      Rails.application.config.prod_environment = false
    end

    subject do
      solr_doc = {
        "id" => 'actest:1', "handle" => doi,
        "title_display" => "Alice's Adventures in Wonderland",
        'author_uni' => [author_one, author_two],
        'free_to_read_start_date' => (Date.current - 1.month).to_s
      }
      @controller.instance_eval { notify_authors_of_new_item(solr_doc) }
    end

    context 'when a notification for each author has previously been sent' do
       before :each do
         Notification.record_new_item_notification(doi, nil, author_one, true)
         Notification.record_new_item_notification(doi, nil, author_two, true)
         subject
       end

      it 'does not sent any notifications' do
        expect(ActionMailer::Base.deliveries.count).to eql 0
      end
    end

    context 'when notifications have not previously been sent' do
      before :each do
        subject
      end

      it 'sends two notifications' do
        expect(ActionMailer::Base.deliveries.count).to eql 2
      end

      it 'sends notification to each author' do
       expect(sent_to).to include(email_author_one, email_author_two)
      end

      it 'records notification to first author was sent' do
        expect(Notification.sent_new_item_notification?(doi, author_one)).to be true
      end

      it 'records notification to second author was sent' do
        expect(Notification.sent_new_item_notification?(doi, author_two)).to be true
      end
    end

    context 'when notification has not been sent to one author' do
      before :each do
        Notification.record_new_item_notification(doi, nil, author_one, true)
        subject
      end

      it 'sends one notification' do
        expect(ActionMailer::Base.deliveries.count).to eql 1
      end

      it 'does not sent notification for first author' do
        expect(sent_to).not_to include email_author_one
      end

      it 'sends notification for second author' do
        expect(sent_to).to include email_author_two
      end

      it 'records notification to second author was sent' do
        expect(Notification.sent_new_item_notification?(doi, author_two)).to be true
      end
    end

    context 'when author is not in LDAP' do
      before :each do
        allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(author_one).and_return(nil)
        subject
      end

      it 'sents to email based on uni' do
        expect(ActionMailer::Base.deliveries.count).to eql 2
        expect(sent_to).to include email_author_one
      end
    end

    context 'when notification fails to sends' do
      before :each do
        email = double
        allow(email).to receive(:deliver_now).and_raise(Net::SMTPSyntaxError)
        allow(NotificationMailer).to receive(:new_item_available).and_return(email)
        subject
      end

      it 'does not sent any emails' do
        expect(ActionMailer::Base.deliveries.count).to eql 0
      end

      it 'records failure in database' do
        expect(Notification.count).to eql 2
        expect(Notification.failed.new_item_notification.to_author(author_one).for_record(doi).count).to eql 1
        expect(Notification.failed.new_item_notification.to_author(author_two).for_record(doi).count).to eql 1
      end
    end
  end
end
