class IndexingController < ApplicationController
  
  include DepositorHelper
  
  def push_indexing_results
    
    start_time = Time.new
    time_id = start_time.strftime("%Y%m%d-%H%M%S")
    logger = Logger.new(Rails.root.to_s + "/log/ac-indexing/#{time_id}.log")
    
    reindexed = params[:reindexed] == nil ? [] : params[:reindexed].split(',')
    new_indexed = params[:new_indexed] == nil ? [] : params[:new_indexed].split(',')
    failed = params[:failed] == nil ? [] : params[:failed].split(',')
    
    logger.info ''
    logger.info '   started: ' + (params[:started] == nil ? '' :  params[:started])
    logger.info '  finished: ' + (params[:finished] == nil ? '' :  params[:finished])
    logger.info 'time spent: ' + (params[:time_spent] == nil ? '' :  params[:time_spent])
    logger.info ''
    logger.info '  reindexed (' + reindexed.size.to_s + ') - ' + (params[:reindexed] == nil ? '' :  params[:reindexed])
    logger.info 'new indexed (' + new_indexed.size.to_s + ') - ' + (params[:new_indexed] == nil ? '' :  params[:new_indexed])
    logger.info '     failed (' + failed.size.to_s + ') - ' + (params[:failed] == nil ? '' :  params[:failed])
    
    
    if(new_indexed.size > 0)
      notifyDepositorsItemAdded(new_indexed)
    end

    render nothing: true 
  end
  
  def ingest_by_cron
    processIndexing(params)
    render nothing: true 
  end  
  
end ### ===================================================== ###