require 'rails_helper'

describe 'Explore', type: :feature do
  # the /explore URL is a custom path for the collections resource controller
  before { visit collections_path }

  it 'renders the CUL header' do
    expect(page).to have_css('div.cul-banner', text: 'Columbia University Libraries')
  end

  displayed_collections = CollectionsController::CONFIG.reject { |category_id| category_id == :produced_at_columbia }
  displayed_collections.each do |category_id, opts|
    it "links to the #{opts[:title]} page" do
      # this needs to look for a link by href
      expect(page).to have_css("a[href=\"/explore/#{category_id.to_s.tr('_', '-')}\"]")
      find(:css, "a[href=\"/explore/#{category_id.to_s.tr('_', '-')}\"]").click
      expect(page).to have_css 'h1', text: opts[:title]
    end
  end

  it 'does not link to the Produced at Columbia page' do
    expect(page).not_to have_css('a[href="/explore/produced-at-columbia"]')
  end
end
