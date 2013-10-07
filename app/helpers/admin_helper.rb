module AdminHelper
  
  
  def alert_msg
      alert_message_model = ContentBlock.find_by_title("alert_message")
      return alert_message_model ? alert_message_model.data : ""     
  end    
  
end
