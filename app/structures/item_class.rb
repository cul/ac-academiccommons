class Item
  
  attr_reader :pid, :title, :handle, :authors_uni
  attr_accessor :pid, :title, :handle, :authors_uni 
  
  def initialize
   @pid, @title, @handle = nil
   @authors_uni = []
  end

end