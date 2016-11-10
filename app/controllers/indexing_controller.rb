class IndexingController < ApplicationController
  include DepositorHelper

  def push_indexing_results

    start_time = Time.new
    time_id = start_time.strftime("%Y%m%d-%H%M%S")
    uploaded_file = UploadedFile.save(params[:reindex_log], Rails.root.to_s + "/log/ac-indexing/", time_id + '.log')

    new_indexed = params[:new_indexed] == nil ? [] : params[:new_indexed].split(',')
    new_embargoed = params[:embargo_new] == nil ? [] : params[:embargo_new].split(',')
    embargo_new_released = params[:embargo_new_released] == nil ? [] : params[:embargo_new_released].split(',')
    failed = params[:failed] == nil ? [] : params[:failed].split(',')

    new_indexed.push(embargo_new_released)
    new_indexed = new_indexed.flatten

    if(new_indexed.size > 0)
      notifyDepositorsItemAdded(new_indexed)
    end

    if(new_embargoed.size > 0)
      notifyDepositorsEmbargoedItemAdded(new_embargoed)
    end

    Notifier.reindexing_summary(params, time_id).deliver

    render nothing: true
  end


  def ingest_by_cron
    processIndexing(params)
    render nothing: true
  end

end
