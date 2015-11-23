class ContactController < ApplicationController
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(params[:message])
    if @message.valid? && @message.content_check
      @message.request = request
      @message.deliver
      flash[:notice] = "Your message has been sent."
      redirect_to root_path 
    elsif @message.valid? && !@message.content_check
      flash[:notice] = "Please insert a valid attachment."
      render :new
    else
      flash[:notice] = "Please fill out all fields"
      render :new
    end
  end
end
