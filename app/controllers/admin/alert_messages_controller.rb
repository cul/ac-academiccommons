module Admin
  class AlertMessagesController < AdminController
    load_and_authorize_resource class: ContentBlock

    def edit
      @alert_message ||= ContentBlock.find_by(title: ContentBlock::ALERT_MESSAGE)
      @alert_message ||= ContentBlock.new
    end

    def update
      Rails.logger.debug params.inspect
      @alert_message = ContentBlock.find_by(title: ContentBlock::ALERT_MESSAGE) || ContentBlock.new(title: ContentBlock::ALERT_MESSAGE)
      @alert_message.data = alert_messages_params[:data]
      @alert_message.user = current_user

      if @alert_message.save
        expire_fragment('alert_message')
        flash[:success] = 'Succesfully updated alert message.'
      else
        flash[:error] = 'There was an error updating the alert message.'
      end

      render :edit
    end

    private

    def alert_messages_params
      params.require(:content_block).permit(:data)
    end
  end
end
