class NotificationsMailer < ActionMailer::Base
  default :from => "megan.oneill38@gmail.com"
  default :to => "megan.oneill38@gmail.com"

  def new_message(message)
    @message = message
    mail(:subject => "DMCA Takedown form")
  end
end
