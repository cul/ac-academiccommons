class DmcasController < ApplicationController
  def new
    @dmca = Dmca.new
  end

  def create
    @dmca = Dmca.new(params[:dmca])
    binding.pry
    if @dmca.valid? && @dmca.content_check
      @dmca.request = request
      @dmca.deliver
      flash[:success] = "Your message has been sent."
      redirect_to(:action => :index) 
    elsif @dmca.valid? && !@dmca.content_check
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
