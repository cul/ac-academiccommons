# frozen_string_literal: true

describe CollectionsController, type: :controller do
  describe 'redirects legacy URLS' do
    it "redirects '/featured' to featured partners collection " do
      expect(get(:show, params: { category_slug: 'featured' })).to redirect_to(
        controller: 'collections', category_slug: 'featured-partners', action: 'show'
      )
    end

    it "redirects '/producedatcolumbia' to produced at columbia collection " do
      expect(get(:show, params: { category_slug: 'producedatcolumbia' })).to redirect_to(
        controller: 'collections', category_slug: 'produced-at-columbia', action: 'show'
      )
    end

    it "redirects '/doctoraltheses' to doctoral theses collection " do
      expect(get(:show, params: { category_slug: 'doctoraltheses' })).to redirect_to(
        controller: 'collections', category_slug: 'doctoral-theses', action: 'show'
      )
    end
  end
end
