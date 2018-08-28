require 'rails_helper'

describe 'My Account', type: :feature do
  include_context 'non-admin user for feature'

  before do
    visit account_path
  end

  it "renders my account title" do
    expect(page).to have_css('li.active', text: 'My Account')
  end

  it "renders read and sign agreement link" do
    expect(page).to have_css('a', text: 'Read and sign the agreement')
  end
end
