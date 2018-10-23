require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'new_item_available' do
    let(:email) { 'abc123@columbia.edu' }
    let(:uni) { 'abc123' }
    let(:name) { 'Jane Doe' }
    let(:mail) { described_class.new_item_available(solr_doc, uni, email, name).deliver_now }

    context 'when document embargoed' do
      let(:solr_doc) do
        SolrDocument.new(
          object_state_ssi: 'A', free_to_read_start_date_ssi: Date.tomorrow.strftime('%Y-%m-%d'),
          title_ssi: 'Alice\'s Adventures in Wonderland', cul_doi_ssi: '10.7945/ALICE'
        )
      end

      it 'renders correct subject' do
        expect(mail.subject).to eq 'Your work is now registered in Academic Commons - TEST'
      end

      it 'renders depositor name' do
        expect(mail.html_part.body).to match 'Jane Doe'
      end

      it 'renders record title' do
        expect(mail.html_part.body).to match 'Alice\'s Adventures in Wonderland'
      end

      it 'renders record persistent url' do
        expect(mail.html_part.body).to match 'https://doi.org/10.7945/ALICE'
      end

      it 'renders date available' do
        expect(mail.html_part.body).to match Date.tomorrow.strftime('%Y-%m-%d')
      end
    end

    context 'when document not embargoed' do
      let(:solr_doc) do
        SolrDocument.new(
          object_state_ssi: 'A', free_to_read_start_date_ssi: Date.current.strftime('%Y-%m-%d'),
          title_ssi: 'Alice\'s Adventures in Wonderland', cul_doi_ssi: '10.7945/ALICE'
        )
      end

      it 'renders correct subject' do
        expect(mail.subject).to eq 'Your work is now available in Academic Commons - TEST'
      end

      it 'renders depositor name' do
        expect(mail.html_part.body).to match 'Jane Doe'
      end

      it 'renders record title' do
        expect(mail.html_part.body).to match 'Alice\'s Adventures in Wonderland'
      end

      it 'renders record persistent url' do
        expect(mail.html_part.body).to match 'https://doi.org/10.7945/ALICE'
      end
    end
  end
end
