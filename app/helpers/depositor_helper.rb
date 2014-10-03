require "person_class"
require "item_class"

module DepositorHelper
  
  include SolrHelper
  include InfoHelper
  
  
  def notifyDepositorsItemAdded(pids)
    
    depositors = prepareDepositorsToNotify(pids)

    depositors.each do | depositor |
      logger.info "\n ============ notifyDepositorsItemAdded ============="
      logger.info "=== uni: " + depositor.uni
      logger.info "=== email: " + depositor.email
      if(depositor.full_name == nil)
        logger.info "=== full_name: "
      else
        logger.info "=== full_name: " + depositor.full_name
      end    
      

      depositor.items_list.each do | item |
        logger.info "------ "
        logger.info "------ item.pid: " + item.pid
        logger.info "------ item.title: " + item.title
        logger.info "------ item.handle: " + item.handle
      end
      
      Notifier.depositor_first_time_indexed_notification(depositor).deliver
    end
    
  end
  
  
  def prepareDepositorsToNotify(pids)
    
    depositors_to_notify = Hash.new
    
    pids.each do | pid |
      
      logger.info "=== process depositors for pid: " + pid

      item = getItem(pid)
      
      logger.info "=== item created for pid: " + pid
       
      logger.debug "=== item.pid: " + item.pid
      logger.debug "=== item.title: " + item.title
      logger.debug "=== item.handle: " + item.handle
      logger.debug "=== item.authors_uni: " + item.authors_uni.size.to_s

      item.authors_uni.each do | uni |
        
        logger.info "=== process uni: " + uni +" depositor for pid: " + pid
        
        if(!depositors_to_notify.key?(uni))     
          depositor = getDepositor(uni)
          depositors_to_notify.store(uni, depositor)
        end  
        
        depositor = depositors_to_notify[uni]
        depositor.items_list << item
        
        logger.info "=== process uni: " + uni +" depositor for pid: " + pid + " === finished"
      end
    end
    
    logger.info "====== depositors_to_notify.size: " + depositors_to_notify.size.to_s
    
    return depositors_to_notify.values
  end
  
  def getDepositor(uni)
    
    person = get_person_info(uni)
 
    (person.email == nil) ?  depositor_email = person.uni + "@columbia.edu" : depositor_email = person.email
    if (person.last_name == nil || person.first_name == nil) 
       logger.info "==== uni: " + person.uni  + " was not found in LDAP ===" 
       depositor_name = nil 
    else 
      depositor_name = person.first_name + ' ' + person.last_name
      
      logger.info "name: " + depositor_name + " was found in LDAP"
    end 
        
    person.email = depositor_email
    person.full_name = depositor_name
    
    return person
  end
  
  def processIndexing(params)

   logger.info "==== started ingest function ==="

      params.each do |key, value|
        logger.info "param: " + key + " - " + value
      end
    
    

    if(params[:cancel])
      existing_time_id = existing_ingest_time_id(params[:cancel])
      if(existing_time_id)
        Process.kill "KILL", params[:cancel].to_i
        File.delete("#{Rails.root}/tmp/#{params[:cancel]}.index.pid")
        log_file = File.open("#{Rails.root}/log/ac-indexing/#{existing_time_id}.log", "a")
        log_file.write("CANCELLED")
        log_file.close
        flash.now[:notice] = "Ingest has been cancelled"
      else
        flash.now[:notice] = "Oh, um, we can't find the process ID #{params[:cancel]}, so we can't cancel it.  It's probably my fault, so I'm really sorry about that."
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

      collections = params[:collections] ? params[:collections].sub(" ", ";") : ""
      items = params[:items] ? params[:items].gsub(/ /, ";") : ""
     
      @existing_ingest_pid = Process.fork do
        
        logger.info "==== started indexing ==="
        
        indexing_results = ACIndexing::reindex({
                                :collections => collections,
                                :items => items,
                                :overwrite => params[:overwrite], 
                                :metadata => params[:metadata], 
                                :fulltext => params[:fulltext],
                                :delete_removed => params[:delete_removed],
                                :time_id => time_id,
                                :executed_by => params[:executed_by] || current_user.login
                                #:executed_by => "test"
                              })
                              
        logger.info "===== finished indexing, starting notifications part ==="                      
        
        if(params[:notify])
          Notifier.reindexing_results(indexing_results[:errors].size.to_s, indexing_results[:indexed_count].to_s, indexing_results[:new_items].size.to_s, time_id).deliver
        end
        
        notifyDepositorsItemAdded(indexing_results[:new_items])
        #notifyDepositorsItemAdded(indexing_results[:results][:success]) # this is for test
        
      end
      Process.detach(@existing_ingest_pid)
      @existing_ingest_time_id = time_id.to_s
    
      logger.info "Started ingest with PID: #{@existing_ingest_pid} (#{@existing_ingest_time_id})"
    
      tmp_pid_file = File.new("#{Rails.root}/tmp/#{@existing_ingest_pid}.index.pid", "w+")
      tmp_pid_file.write(@existing_ingest_time_id)
      tmp_pid_file.close
      
    end

  end
  
end