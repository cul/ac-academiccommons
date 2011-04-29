class WelcomeController < ApplicationController
  layout "no_sidebar"

  def logout
   redirect_to :controller => 'catalog', :action => 'index'  end
 end
