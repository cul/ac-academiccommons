class AdminController < ApplicationController
  
  include DepositorHelper
  include InfoHelper

  #before_filter :require_admin, :except => [:ingest_by_cron]
  before_filter :require_admin
  before_filter :add_jhtmlarea, :only => [:edit_home_page]
  
  #layout "no_sidebar"
  layout "application"
  
  # def ingest_by_cron
    # processIndexing(params)
    # render nothing: true 
  # end

  def ingest
    
      processIndexing(params)

      if(params[:executed_by])
        render nothing: true 
      end  
  end

  def existing_ingest_time_id(pid)
    if(pid_exists?(pid))
      running_tmp_pid_file = File.open("#{Rails.root}/tmp/#{pid}.index.pid")
      return running_tmp_pid_file.gets
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
  
  
  def edit_alert_message
    if params[:commit]   
      if existing_block = ContentBlock.find_by_title("alert_message")
        existing_block.update_attributes!(:user => current_user, :data => params[:alert_message])
      else
        ContentBlock.create!(:title => "alert_message", :user => current_user, :data => params[:alert_message])
      end
    end

    alert_message_model = ContentBlock.find_by_title("alert_message")
    @alert_message = alert_message_model ? alert_message_model.data : ""
  end
  
  
  def deposits

    if(params[:archive])
      deposit_to_archive = Deposit.find(params[:archive])
      if(deposit_to_archive)
        if(File.exists?(Rails.root.to_s + "/" + deposit_to_archive.file_path))
          File.delete(Rails.root.to_s + "/" + deposit_to_archive.file_path)
        end
        deposit_to_archive.archived = 1
        deposit_to_archive.save
      end
    end
    @deposits = Deposit.find(:all, :conditions => {:archived => false}, :order => "created_at")
    
  end

  def agreements
      @agreements = Agreement.find(:all)
      respond_to do |format|
         format.html
         format.csv { send_data Agreement.to_csv }
      end
  end
  
  def student_agreements
      @agreements = StudentAgreement.find(:all)
      respond_to do |format|
         format.html
         format.csv { send_data StudentAgreement.to_csv }
      end
  end  

  
  def show_deposit
    @deposit = Deposit.find(params[:id])
  end
  
  def download_deposit_file
    @deposit = Deposit.find(params[:id])
    send_file Rails.root.to_s + "/" + @deposit.file_path
  end
  
  private

  def add_jhtmlarea
    javascript_includes << ["jHtmlArea-0.7.0.min", "jHtmlArea.ColorPickerMenu-0.7.0.min"]
    stylesheet_links << ["jHtmlArea", "jHtmlArea.ColorPickerMenu"]
  end
  
end
