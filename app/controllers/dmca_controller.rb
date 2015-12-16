class DmcaController < ApplicationController
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(params[:message])
    if @message.valid? && @message.content_check
      @message.request = request
      @message.deliver
      flash[:success] = "Your message has been sent."
      redirect_to(:action => :index) 
    elsif @message.valid? && !@message.content_check
      flash[:error] = "Please insert a valid attachment."
      render :new
    else
      flash[:error] = "Please fill out all fields"
      render :new
    end
  end

  def index
    
  end


end
