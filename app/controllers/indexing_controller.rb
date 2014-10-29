class IndexingController < ApplicationController
  
  include DepositorHelper
  
  def push_indexing_results
    
    start_time = Time.new
    time_id = start_time.strftime("%Y%m%d-%H%M%S")
    logger = Logger.new(Rails.root.to_s + "/log/ac-indexing/#{time_id}.log")
    
    reindexed = params[:reindexed] == nil ? [] : params[:reindexed].split(',')
    new_indexed = params[:new_indexed] == nil ? [] : params[:new_indexed].split(',')
    
    embargo_new = params[:embargo_new] == nil ? [] : params[:embargo_new].split(',')
    embargo_reindexed = params[:embargo_reindexed] == nil ? [] : params[:embargo_reindexed].split(',')
    embargo_new_released = params[:embargo_new_released] == nil ? [] : params[:embargo_new_released].split(',')
    embargo_released_reindexed = params[:embargo_released_reindexed] == nil ? [] : params[:embargo_released_reindexed].split(',')
    
    failed = params[:failed] == nil ? [] : params[:failed].split(',')
    
    logger.info ''
    logger.info '                     started: ' + (params[:started] == nil ? '' :  params[:started])
    logger.info '                    finished: ' + (params[:finished] == nil ? '' :  params[:finished])
    logger.info '                  time spent: ' + (params[:time_spent] == nil ? '' :  params[:time_spent])
    logger.info ''
    logger.info '               all processed: '  + params[:all_processed]
    logger.info ''
    logger.info '                 new indexed (' + new_indexed.size.to_s + ') - ' + (params[:new_indexed] == nil ? '' :  params[:new_indexed])
    logger.info '                   reindexed (' + reindexed.size.to_s + ') - ' + (params[:reindexed] == nil ? '' :  params[:reindexed])
    logger.info ''
    logger.info '               new embargoed (' + embargo_new.size.to_s + ') - ' + (params[:embargo_new] == nil ? '' :  params[:embargo_new])
    logger.info '         embargoed reindexed (' + embargo_reindexed.size.to_s + ') - ' + (params[:embargo_reindexed] == nil ? '' :  params[:embargo_reindexed])
    logger.info '      new embargoed released (' + embargo_new_released.size.to_s + ') - ' + (params[:embargo_new_released] == nil ? '' :  params[:embargo_new_released])
    logger.info 'embargoed released reindexed (' + embargo_released_reindexed.size.to_s + ') - ' + (params[:embargo_released_reindexed] == nil ? '' :  params[:embargo_released_reindexed])
    logger.info ''
    logger.info '                      failed (' + failed.size.to_s + ') - ' + (params[:failed] == nil ? '' :  params[:failed])
    logger.info ''

    
    if(new_indexed.size > 0)
      notifyDepositorsItemAdded(new_indexed)
    end
    
    if(embargo_new_released.size > 0)
      notifyDepositorsItemAdded(embargo_new_released)
    end

    render nothing: true 
  end
  
  def ingest_by_cron
    processIndexing(params)
    render nothing: true 
  end  
  
end ### ===================================================== ###