class AdminController < ApplicationController
  before_filter :require_admin 
  before_filter :add_jhtmlarea, :only => [:edit_home_page]
  
  layout "no_sidebar"

  def ingest_history
    
    @logs = []
    Dir.glob("#{Rails.root}/log/indexing/*") do |log_file_path|
      log = {}
      log[:filepath] = log_file_path
      log[:filename] = File.basename(log_file_path)
      time_id = log[:filename].gsub(/reindex_/, '').gsub(/\.log/, '')
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
    headers["Content-Disposition"] = "attachment;filename=\"reindex_#{params[:id]}.log\""
    render :text => File.open("#{Rails.root}/log/indexing/reindex_#{params[:id]}.log").read
    
  end

  def ingest

#    if params[:commit] == "Commit"
#      items, collections = [params[:items], params[:collections]].collect { |pids| pids.split(" ").collect { |pid| fedora_server.item(pid) }}
#      
#      solr_params = {:items => items, :format => "ac2", :collections => collections} 
#
#      solr_params[:fulltext] = params[:fulltext] == "1"
#      solr_params[:metadata] = params[:metadata] == "1"
#      solr_params[:overwrite] = params[:overwrite] == "1"
#      solr_params[:skip] = params[:skip] ? params[:skip].to_i : nil
#      solr_params[:process] = params[:process] ? params[:process].to_i : nil
#
#
#      @results = solr_server.ingest(solr_params)
#
#      if params[:overwrite] && params[:process]
#        params[:skip] = params[:skip].to_i + params[:process].to_i
#      end
#        
#      flash.now[:notice] = "Ingest successful."
#    end
#
#
#    
#
#    if params[:commit] == "Delete All"
#      solr_server.delete_index
#
#      flash.now[:notice] = "Index deleted."
#    end

    if(!params[:cancel].nil?)
      # we just want to make sure that we're going to actually kill a pid that is an ac reindex
      if(`ps -p #{params[:cancel]}`.to_s.include?("ac:reindex"))
        get_pid_children(params[:cancel]).each do |child|
          `kill -9 #{child}`
        end
        `kill -9 #{params[:cancel]}`
        File.delete("#{Rails.root}/tmp/#{params[:cancel]}.index.pid")
        flash.now[:notice] = "Ingest has been cancelled"
        end
    end

    # set time
    time = Time.new
    time_id = time.strftime("%Y%m%d-%H%M%S")
    @existing_ingest_pid = nil
    @existing_ingest_time_id = nil

    # clean up temp pid files for indexing runs
    Dir.glob("#{Rails.root}/tmp/*.index.pid") do |tmp_pid_file|
      first_namepart, *rest_namepart = File.basename(tmp_pid_file).split(/\./)
      @existing_ingest_time_id = existing_ingest_time_id(first_namepart)
      if(@existing_ingest_time_id == nil)
        File.delete(tmp_pid_file)
      else
        @existing_ingest_pid = first_namepart
      end
    end
    
    if(params[:commit] == "Commit" && @existing_ingest_time_id.nil? && !params[:cancel])
      # build the rake parameters
      collections = params[:collections] ? params[:collections].sub(" ", ";") : ""
      items = params[:items] ? params[:items].sub(" ", ";") : ""

      cmd = "rake ac:reindex[\"#{collections}\",\"#{items}\",#{params[:overwrite]},#{params[:metadata]},#{params[:fulltext]},#{params[:delete_removed]}] RAILS_ENV=#{RAILS_ENV} 2>&1 >> #{Rails.root}/log/indexing/reindex_#{time_id}.log"
      puts "Executing #{cmd}"
      @existing_ingest_pid = exec_background(cmd).to_s
      @existing_ingest_time_id = time_id.to_s
    
      tmp_pid_file = File.new("#{Rails.root}/tmp/#{@existing_ingest_pid}.index.pid", "w+")
      tmp_pid_file.write(@existing_ingest_time_id)
      tmp_pid_file.close
    end
    
  end

  def existing_ingest_time_id(pid)
    result = {}
    begin
      if(pid_exists?(pid))
        running_tmp_pid_file = File.open("#{Rails.root}/tmp/#{pid}.index.pid")
        return running_tmp_pid_file.gets
      end
    rescue Exception => e
      puts e.inspect
      return nil
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
