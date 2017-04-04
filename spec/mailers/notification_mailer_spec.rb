require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do

  describe 'new_item_available' do
    let(:depositor) { OpenStruct.new(uni: 'abc123', name: 'Jane Doe', email: 'abc123@columbia.edu') }
    let(:mail) { described_class.new_item_available(depositor, solr_doc).deliver_now }

    context 'when document embargoed' do
      let(:solr_doc) do
        SolrDocument.new({
          object_state_ssi: 'A', free_to_read_start_date: Date.tomorrow.strftime('%Y-%m-%d'),
          title_display: 'Alice\'s Adventures in Wonderland', handle: '10.7945/ALICE'
        })
      end

      it 'renders correct subject' do
        expect(mail.subject).to eq 'Your work is now registered in Academic Commons - TEST'
      end

      it 'renders depositor name' do
        expect(mail.body.encoded).to match 'Jane Doe'
      end

      it 'renders record title' do
        expect(mail.body.encoded).to match 'Alice&#39;s Adventures in Wonderland'
      end

      it 'renders record persistent url' do
        expect(mail.body.encoded).to match 'https://doi.org/10.7945/ALICE'
      end

      it 'renders date available' do
        expect(mail.body.encoded).to match Date.tomorrow.strftime('%Y-%m-%d')
      end
    end

    context 'when document not embargoed' do
      let(:solr_doc) do
        SolrDocument.new({
          object_state_ssi: 'A', free_to_read_start_date: Date.today.strftime('%Y-%m-%d') ,
          title_display: 'Alice\'s Adventures in Wonderland', handle: '10.7945/ALICE'
        })
      end

       it 'renders correct subject' do
         expect(mail.subject).to eq 'Your work is now available in Academic Commons - TEST'
       end

       it 'renders depositor name' do
         expect(mail.body.encoded).to match 'Jane Doe'
       end

       it 'renders record title' do
         expect(mail.body.encoded).to match 'Alice&#39;s Adventures in Wonderland'
       end

       it 'renders record persistent url' do
         expect(mail.body.encoded).to match 'https://doi.org/10.7945/ALICE'
       end
    end
  end
end
