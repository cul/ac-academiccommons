class AdminController < ApplicationController
  
  include DepositorHelper

  before_filter :require_admin, :except => [:ingest_by_cron, :download_ingest_log]
  before_filter :add_jhtmlarea, :only => [:edit_home_page]
  
  #layout "no_sidebar"
  layout "application"

  def ingest_history
    
    @logs = []
    Dir.glob("#{Rails.root}/log/ac-indexing/*.log") do |log_file_path|
      log = {}
      log[:filepath] = log_file_path
      log[:filename] = File.basename(log_file_path)
      time_id = log[:filename].gsub(/\.log/, '')
      log[:time_id] = time_id.to_s
      log[:year] = time_id[0..3].to_i
      log[:month] = time_id[4..5].to_i
      log[:day] = time_id[6..7].to_i
      log[:hour] = time_id[9..10].to_i
      log[:minute] = time_id[11..12].to_i
      log[:second] = time_id[13..14].to_i
      log[:time] = Time.mktime(log[:year], log[:month], log[:day], log[:hour], log[:minute], log[:second]).strftime("%B %e, %Y %r")
      @logs << log 
    end
    
    @logs.reverse!
    
  end

  def download_ingest_log
    
    headers["Content-Type"] = "application/octet-stream"
    headers["Content-Disposition"] = "attachment;filename=\"#{params[:id]}.log\""
    render :text => File.open("#{Rails.root}/log/ac-indexing/#{params[:id]}.log").read
    
  end
  
  def ingest_by_cron
    processIndexing(params)
    render nothing: true 
  end

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
