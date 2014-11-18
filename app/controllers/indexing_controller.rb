class IndexingController < ApplicationController
  
  include DepositorHelper
  
  
  def push_indexing_results
    
    start_time = Time.new
    time_id = start_time.strftime("%Y%m%d-%H%M%S")
    logger = Logger.new(Rails.root.to_s + "/log/ac-indexing/#{time_id}.log")
    
    new_indexed = params[:new_indexed] == nil ? [] : params[:new_indexed].split(',')
    new_embargoed = params[:embargo_new] == nil ? [] : params[:embargo_new].split(',')
    embargo_new_released = params[:embargo_new_released] == nil ? [] : params[:embargo_new_released].split(',')
    
    
    logger.info ''
    logger.info '                     started - ' + (params[:started] == nil ? '' :  params[:started])
    logger.info '                    finished - ' + (params[:finished] == nil ? '' :  params[:finished])
    logger.info '                  time spent - ' + (params[:time_spent] == nil ? '' :  params[:time_spent])
    logger.info ''
    logger.info '               all processed - '  + params[:all_processed]
    logger.info ''
    logger.info '                 new indexed - ' + new_indexed.size.to_s + ' (' + (params[:new_indexed] == nil ? '' :  params[:new_indexed]) + ')'
    logger.info '                   reindexed - ' + params[:reindexed]
    logger.info ''
    logger.info '               new embargoed - ' + new_embargoed.size.to_s + ' (' + (params[:embargo_new] == nil ? '' :  params[:embargo_new]) + ')'
    logger.info '         embargoed reindexed - ' + params[:embargo_reindexed]
    logger.info '      new embargoed released - ' + embargo_new_released.size.to_s + ' (' + (params[:embargo_new_released] == nil ? '' :  params[:embargo_new_released]) + ')'
    logger.info 'embargoed released reindexed - ' + params[:embargo_released_reindexed]
    logger.info ''
    logger.info '                      failed - ' + params[:failed]
    logger.info ''

    new_indexed.push(embargo_new_released)
    new_indexed = new_indexed.flatten

    if(new_indexed.size > 0)
      notifyDepositorsItemAdded(new_indexed)
    end
    
    if(new_embargoed.size > 0)
      notifyDepositorsEmbargoedItemAdded(new_embargoed)
    end  

    render nothing: true 
  end  
  
  
  def ingest_by_cron
    processIndexing(params)
    render nothing: true 
  end  
  
end ### ===================================================== ###