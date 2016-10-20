require 'rails_helper'

RSpec.describe InfoController, type: :feature do

  context "about" do
    it 'render about page' do
      visit "about"
      expect(page).to have_content "Columbia University's Research Repository"
    end
  end
end
