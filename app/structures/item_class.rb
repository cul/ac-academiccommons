class Item
  
  attr_reader :pid, :title, :handle, :authors_uni, :free_to_read_start_date
  attr_accessor :pid, :title, :handle, :authors_uni, :free_to_read_start_date 
  
  def initialize
   @pid, @title, @handle, @free_to_read_start_date = nil
   @authors_uni = []
  end

end