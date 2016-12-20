require 'rails_helper'

RSpec.describe Notifier, type: :mailer do

  describe '.author_monthly' do
    let(:mail) {
      Notifier.author_monthly('abc123@columbia.edu', 'abc123', Date.yesterday,
                              Date.today, '', '', '', '', '', '')
    }

    it 'contains correct unsubscribe link' do
      expect(mail.body.to_s).to have_link('click here', statistics_unsubscribe_monthly_url(author_id: 'abc123', chk: 'abc123'.crypt("xZ")))
    end
  end
end
