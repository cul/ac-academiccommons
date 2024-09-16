require 'rails_helper'

describe 'myworks', type: :feature do
  include_context 'non-admin user for feature'

  context 'when author has available works' do
    before do
      FactoryBot.create(:view_stat)
      FactoryBot.create(:download_stat)
      FactoryBot.create(:download_stat)
      FactoryBot.create(:view_stat, at_time: Time.current - 1.month)
      visit myworks_path
    end

    it 'displays available works' do
      expect(page).to have_content 'Alice\'s Adventures in Wonderland'
    end

    it 'displays correct download statistics' do
      within :xpath, '//tr/td/a[@href="/doi/10.7916/ALICE"]/../..' do
        expect(page).to have_xpath 'td[2]', text: '0'
        expect(page).to have_xpath 'td[3]', text: '2'
      end
    end

    it 'displays correct view statistics' do
      within :xpath, '//tr/td/a[@href="/doi/10.7916/ALICE"]/../..' do
        expect(page).to have_xpath 'td[4]', text: '1'
        expect(page).to have_xpath 'td[5]', text: '2'
      end
    end
  end

  context 'when author has embargoed works' do
    let(:embargoed_solr_params) do
      {
        qt: 'search',
        fq: ['author_uni_ssim:"tu123"', 'object_state_ssi:"A"', 'free_to_read_start_date_dtsi:[NOW+1DAYS TO *]', "has_model_ssim:\"#{ContentAggregator.to_class_uri}\""],
        rows: 100_000
      }
    end
    let(:solr_response) do
      wrap_solr_response_data(
        'response' => {
          'docs' => [
            { 'id' => '10.7916/TESTDOC10', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
              'cul_doi_ssi' => '10.7916/TESTDOC10', 'fedora3_pid_ssi' => 'actest:10', 'genre_ssim' => '', 'publisher_doi_ssi' => '',
              'free_to_read_start_date_ssi' => Date.current.tomorrow.strftime('%Y-%m-%d') }
          ]
        }
      )
    end

    before do
      allow(Blacklight.default_index).to receive(:search).with(any_args).and_call_original
      allow(Blacklight.default_index).to receive(:search).with(embargoed_solr_params).and_return(solr_response)
      visit myworks_path
    end

    it 'displays embargoed works' do
      expect(page).to have_text 'Embargoed Works'
      expect(page).to have_link 'First Test Document', href: '/doi/10.7916/TESTDOC10'
    end
  end

  context 'when deposits are enabled' do
    before do
      SiteOption.create!(name: SiteOption::DEPOSITS_ENABLED, value: true)
      visit myworks_path
    end

    it 'links to the upload page' do
      # this needs to look for a link by href
      expect(page).to have_css('a[href="/upload"]')
    end
  end

  context 'when deposits are disabled' do
    before do
      SiteOption.create!(name: SiteOption::DEPOSITS_ENABLED, value: false)
      visit myworks_path
    end

    it 'does not link to the upload page' do
      expect(page).not_to have_css('a[href="/upload"]')
    end
  end
end
