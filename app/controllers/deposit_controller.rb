class DepositController < ApplicationController
  
  def submit
    
    if(params[:acceptedAgreement] == "agree")
      uploaded_file = UploadedFile.save(params[:file], params[:uni] + "_" + params[:file].original_filename)
      Notifier.deliver_new_deposit(params)
    else
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "index"
    end
    
  end
  
end
