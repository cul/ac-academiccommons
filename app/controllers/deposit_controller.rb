class DepositController < ApplicationController
    
  def submit
    
    if(params[:acceptedAgreement] == "agree")
      uploaded_file = UploadedFile.save(params[:file], "data/self-deposit-uploads/#{params[:uni]}", params[:file].original_filename)
      file_path = "data/self-deposit-uploads/#{params[:uni]}/#{params[:file].original_filename}"
      deposit = Deposit.create(
        :agreement_version => params["AC-agreement-version"],
        :uni => params[:uni],
        :name => params[:name],
        :email => params[:email],
        :file_path => file_path,
        :title => params[:title],
        :authors => params[:author],
        :abstract => params[:abstr],
        :url => params[:url],
        :doi_pmcid => params[:doi_pmcid],
        :notes => params[:software]
      )
      Notifier.deliver_new_deposit(root_url, deposit)
    else
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "index"
    end
    
  end
  
  def submit_author_agreement
    if(params[:acceptedAgreement] == "agree")
      Notifier.deliver_new_author_agreement(params)
    else
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "agreement_only"
    end
  end
  
end
