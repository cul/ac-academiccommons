class AdminController < ApplicationController
  authorize_resource

  layout 'admin'

  def edit_alert_message
    if params[:commit]
      if existing_block = ContentBlock.find_by_title('alert_message')
        existing_block.update_attributes!(user: current_user, data: params[:alert_message])
      else
        ContentBlock.create!(title: 'alert_message', user: current_user, data: params[:alert_message])
      end
      expire_fragment('alert_message')
    end

    alert_message_model = ContentBlock.find_by_title('alert_message')
    @alert_message = alert_message_model ? alert_message_model.data : ''
  end


  def deposits

    if(params[:archive])
      deposit_to_archive = Deposit.find(params[:archive])
      if(deposit_to_archive)
        if(File.exists?(Rails.root.to_s + '/' + deposit_to_archive.file_path))
          File.delete(Rails.root.to_s + '/' + deposit_to_archive.file_path)
        end
        deposit_to_archive.archived = 1
        deposit_to_archive.save
      end
    end
    @deposits = Deposit.where(archived: false).order(:created_at)

  end

  def agreements
      @agreements = Agreement.all
      respond_to do |format|
         format.html
         format.csv { send_data Agreement.to_csv }
      end
  end

  def show_deposit
    @deposit = Deposit.find(params[:id])
  end

  def download_deposit_file
    @deposit = Deposit.find(params[:id])
    send_file Rails.root.to_s + '/' + @deposit.file_path
  end
end
