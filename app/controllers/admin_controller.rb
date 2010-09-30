class AdminController < ApplicationController
  before_filter :require_admin 
  before_filter :add_jhtmlarea, :only => [:edit_home_page]
  
  layout "no_sidebar"

  def ingest
    if params[:commit] == "Commit"
      items, collections = [params[:items], params[:collections]].collect { |pids| pids.split(" ").collect { |pid| fedora_server.item(pid) }}

      solr_server.ingest(:items => items, :collections => collections, :format => "ac2") 
      flash[:notice] = "Ingest successful."
    end


    

    if params[:commit] == "Delete All"
      Blacklight.solr.delete_by_query("*:*")
      Blacklight.solr.commit

      flash[:notice] = "Index deleted."
    end

  end



  def edit_home_page
    if params[:commit]
      if existing_block = ContentBlock.find_by_title("Home Page")
        existing_block.update_attributes!(:user => current_user, :data => params[:home_page_data])
      else
        ContentBlock.create!(:title => "Home Page", :user => current_user, :data => params[:home_page_data])
      end

    end

    home_block = ContentBlock.find_by_title("Home Page")
    @home_block_data = home_block ? home_block.data : ""
  end
  
  private

  def add_jhtmlarea
    
    javascript_includes << ["jHtmlArea-0.7.0.min", "jHtmlArea.ColorPickerMenu-0.7.0.min"]
    stylesheet_links << ["jHtmlArea", "jHtmlArea.ColorPickerMenu"]
  end
end
