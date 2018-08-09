require 'rails_helper'

describe 'Explore', type: :feature do
  # the /explore URL is a custom path for the collections resource controller
  before { visit collections_path }

  it 'renders the CUL header' do
    expect(page).to have_css('div.cul-banner', text: 'Columbia University Libraries')
  end

  CollectionsController::CONFIG.each do |category_id, opts|
    it "links to the #{opts[:title]} page" do
      # this needs to look for a link by href
      expect(page).to have_css("a[href=\"/explore/#{category_id}\"]")
      find(:css, "a[href=\"/explore/#{category_id}\"]").click
      expect(page).to have_css 'h1', text: opts[:title]
    end
  end
end
